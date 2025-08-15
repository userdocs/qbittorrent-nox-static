interface GlossaryEntry {
	compiledContent: () => Promise<string>;
	Content: any;
	file: string;
	toString: () => string;
}

export class GlossaryError extends Error {
	constructor(message: string, public code: string) {
		super(message);
		this.name = 'GlossaryError';
	}
}

// Content cache for performance
const contentCache = new Map<string, string>();

// Basic HTML sanitization
export const sanitizeHtml = (html: string): string => {
	return html
		.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
		.replace(/javascript:/gi, '')
		.replace(/on\w+\s*=/gi, '');
};

// Generate unique ID with crypto fallback
export const generateUniqueId = (id: string): string => {
	try {
		return `modal-${id}-${crypto.randomUUID().slice(0, 6)}`;
	} catch {
		// Fallback for environments without crypto.randomUUID
		return `modal-${id}-${Math.random().toString(36).slice(2, 8)}`;
	}
};

// Get cached content with error handling
const getCachedContent = async (id: string, post: GlossaryEntry): Promise<string> => {
	if (contentCache.has(id)) {
		return contentCache.get(id)!;
	}

	try {
		const content = await post.compiledContent();
		const htmlContent = String(content);
		contentCache.set(id, htmlContent);
		return htmlContent;
	} catch (e) {
		const msg = e instanceof Error ? e.message : String(e);
		throw new GlossaryError(`Failed to extract content for "${id}": ${msg}`, 'CONTENT_EXTRACTION_FAILED');
	}
};

// Escape regex special characters
const escapeRegExp = (s: string): string => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

export interface LoadedGlossaryContent {
	primaryHtml: string;
	moreHtml: string;
	hasMore: boolean;
}

export const loadGlossaryEntry = async (id: string): Promise<LoadedGlossaryContent> => {
	const posts = import.meta.glob<GlossaryEntry>(
		"/src/content/docs/glossary/*.md",
		{ eager: true }
	);

	if (!id) {
		throw new GlossaryError("Modal id parameter is required", 'MISSING_ID');
	}

	const safeId = escapeRegExp(String(id));
	const regex = new RegExp(`(?:${safeId})\\.(?:md|mdx)$`);
	const [, post] = Object.entries(posts).find(([p]) => regex.test(p)) ?? [];

	if (!post) {
		const availableEntries = Object.keys(posts)
			.map(path => path.split('/').pop()?.replace(/\.mdx?$/, ''))
			.filter(Boolean)
			.slice(0, 5);

		throw new GlossaryError(
			`Glossary entry "${id}" not found. Available entries include: ${availableEntries.join(', ')}`,
			'ENTRY_NOT_FOUND'
		);
	}

	const htmlContent = await getCachedContent(id, post);

	if (!htmlContent || htmlContent.trim().length === 0) {
		throw new GlossaryError(`Empty content for "${id}"`, 'EMPTY_CONTENT');
	}

	// Split at any <hr> tag variant case-insensitively
	const htmlSplit = htmlContent.split(/<hr[\s\S]*?>/i);
	if (!htmlSplit.length) {
		throw new GlossaryError(`Invalid content format for "${id}"`, 'INVALID_FORMAT');
	}

	const primaryHtml = sanitizeHtml(htmlSplit[0] ?? "");
	const moreHtml = sanitizeHtml(htmlSplit[1] ?? "");
	const hasMore = Boolean(moreHtml && moreHtml.trim().length > 0);

	return { primaryHtml, moreHtml, hasMore };
};