import Home from "./Home"
import React from "react";
import { BrowserRouter as Router, Route } from "react-router-dom";
import Contact from "./contact";
import Links from "./Links";

function App() {
  return (
    // <Switch>
    <>
          <Router>
            <Route exact path="/links"><Links /></Route>
            <Route exact path="/contact"><Contact /></Route>
            <Route exact path="/"><Home /></Route>
          </Router>
    </>
    // </Switch>
  );
}

export default App;
