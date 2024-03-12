import { useState, useEffect } from "react";
import Toggle from "react-toggle";
import "react-toggle/style.css";
import { GiBrain } from "react-icons/gi";
import { MdOutlineMenuBook } from "react-icons/md";

function getToggled() {
    const toggle = window.localStorage.getItem("advanced");
    return JSON.parse(toggle);
}

function setToggled(toggled) {
    const toggledJSON = JSON.stringify(toggled);
    window.localStorage.setItem("advanced", toggledJSON);
}

function App() {
    const [toggle, setToggle] = useState(getToggled());

    useEffect(() => {
        setToggled(toggle);
    }, [toggle]);

    const handleChange = () => {
        setToggle((prev) => !prev);
        for (let element of document.getElementsByClassName(
            "Advanced-class"
        )) {
            {
                toggle
                    ? (element.style.display = "none")
                    : (element.style.display = "block");
            }
        }
    };

    return (
        <div className="toggle-div">
            <label for="advanced-toggle" hidden="hidden" className="toggle-label">Advanced Toggle</label>
            <Toggle
                name="advanced-toggle"
                aria-label="Advanced Toggle"
                id="advanced-toggle"
                className="toggle-toggle"
                checked={toggle}
                icons={{
                    checked: <GiBrain />,
                    unchecked: <MdOutlineMenuBook />,
                }}
                onChange={handleChange}
            ></Toggle>
        </div >

    );
}

export default App;
