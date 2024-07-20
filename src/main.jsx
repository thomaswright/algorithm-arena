import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import App2 from "./App.res.mjs";

import "./index.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App2 />
  </React.StrictMode>
);
