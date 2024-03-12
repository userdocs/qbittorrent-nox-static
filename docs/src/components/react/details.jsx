
export function Details({ summary, children }) {

    return (
        <>
            <div className="custom-details-container">
                <details className="custom-details">
                    <summary className="custom-summary">{summary}</summary>
                    <div className="custom-content">
                        {children}
                    </div>
                </details>
            </div>
        </>
    );
}

export default Details