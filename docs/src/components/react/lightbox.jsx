import * as React from "react";
import Lightbox from "yet-another-react-lightbox";
import "yet-another-react-lightbox/styles.css";

export default function App({ path, width, height }) {
    const [open, setOpen] = React.useState(false);

    return (
        <>
            <img src={path} onClick={() => setOpen(true)} width={width} height={height} />

            <Lightbox
                open={open}
                close={() => setOpen(false)}
                slides={[{ src: path }]}
            />
        </>
    );
}
