import type { ComponentProps } from 'react';
import React from 'react';
import CopyButton from '@theme/CodeBlock/CopyButton';
import type { Props } from '@theme/MDXComponents/Code';
import codeBlockStyles from './CodeBlock.module.css';
import clsx from 'clsx';

function shouldBeInline(props: Props): boolean {
  return (
    // empty code blocks have no props.children,
    // see https://github.com/facebook/docusaurus/pull/9704
    typeof props.children !== 'undefined' &&
    React.Children.toArray(props.children).every(
      (el) => typeof el === 'string' && !el.includes('\n'),
    )
  );
}

function getTextForCopy(node: React.ReactNode): string {
  if (node === null) return '';

  switch (typeof node) {
    case 'string':
    case 'number':
      return node.toString();
    case 'boolean':
      return '';
    case 'object':
      if (node instanceof Array) return node.map(getTextForCopy).join('');
      if ('props' in node) {
        // skip lines that are "removed" in a diff by adding some recognizable whitespace
        if (node.props.className?.includes('diff remove')) return '\n \n';
        return getTextForCopy(node.props.children);
      }
    default:
      return '';
  }
}

function stripDiffSpacer(str: string): string {
  // remove the extra space added to removed lines in diffs
  return str.replace(/\n \n\n/g, '');
}

function CodeBlock(props: ComponentProps<'code'>): JSX.Element {
  const codeRef = React.useRef<HTMLElement>(null);
  const language = props.className?.replace(/language-/, '');
  const code = stripDiffSpacer(getTextForCopy(props.children));

  return (
    <div className={codeBlockStyles.CodeBlock}>
      <div className={codeBlockStyles.header}>
        <div>{language}</div>
      </div>
      <div className={codeBlockStyles.content}>
        <pre className={clsx(codeBlockStyles.pre, 'shiki')}>
          <code {...props} ref={codeRef} />
        </pre>
        <CopyButton className={codeBlockStyles.button} code={code} />
      </div>
    </div>
  );
}

export default function MDXCode(props): JSX.Element {
  return shouldBeInline(props) ? <code {...props} /> : <CodeBlock {...props} />;
}
