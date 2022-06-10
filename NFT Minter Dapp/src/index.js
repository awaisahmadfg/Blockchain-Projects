import ReactDOM from 'react-dom';
import './App.css';
import App from "./App"
import { BrowserRouter } from "react-router-dom";
import 'bootstrap/dist/js/bootstrap.bundle.min';
import 'bootstrap/dist/css/bootstrap.min.css';
import { MoralisProvider } from "react-moralis";

import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

require("dotenv").config();

ReactDOM.render(
  <BrowserRouter>
    <MoralisProvider serverUrl={process.env.REACT_APP_SERVER_URL} appId={process.env.REACT_APP_APP_ID}>
      <ToastContainer 
      position="top-center"
      autoClose={5000}
      hideProgressBar={false}
      newestOnTop={false}
      closeOnClick
      rtl={false}
      pauseOnFocusLoss
      draggable
      pauseOnHover
      />
      <App />
    </MoralisProvider>
  </BrowserRouter>,

  document.getElementById('root')
);


