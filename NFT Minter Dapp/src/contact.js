import gifimg from './images/gifi.gif';
import logo from './images/logo.png'

import React from "react";


function Contact(){
    return(
        <div>
            <div className='container '>
                <nav className="navbar navbar-expand-lg navbar-light ">
                    <a className="navbar-brand" href="/"><img className='navlogo' src={logo} /></a>
                    <button className="navbar-toggler bg-light ml-auto" type="button" data-toggle="collapse" data-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                        <span className="navbar-toggler-icon"></span>
                    </button>

                    <div className="collapse navbar-collapse " id="navbarNav">
                        <ul className="navbar-nav text-center">
                            <li className="nav-item active">
                                <span className="px-lg-4 NavBtn  "><a href="/#home">HOME</a></span>
                            </li>
                            <li className="nav-item ">
                                <span className="px-lg-4 NavBtn ">  <a href="/#about">ABOUT</a></span>
                            </li>
                            <li className="nav-item">
                                <span className="px-lg-4 NavBtn" href="#"> <a href='/#Roadmap'>ROADMAP</a></span>
                            </li>
                            <li className="nav-item">
                                <span className="px-lg-4 NavBtn" href="#"> <a href='/#Team'>TEAM</a></span>
                            </li> 
                            <li className="nav-item">
                                <span className="px-lg-4 NavBtn" href="#"> <a href='/#Faq'>FAQ</a></span>
                            </li>
                            <li className="nav-item">
                                <span className="px-lg-4 NavBtn" href="#"> <a href='/contact'>Contact</a></span>
                            </li>
                        </ul>
                        <span className='d-block ml-auto text-center'>
                            <a href="https://twitter.com/LazyLeopardClub" target="_blank"><i className="fab fa-twitter mx-2 py-3 icons"></i></a>
                            <a href="https://discord.gg/kPAZkJpZsA" target="_blank"><i className="fab fa-discord mx-2 py-3 icons"></i></a>
                            <a href="https://www.instagram.com/lazyleopardclub/ " target="_blank"><i className="fab fa-instagram mx-2 py-3 icons"></i></a>
                        </span>
                    </div>
                </nav>
            </div>
            <div className='container formsection'>
                <div className='row py-3 text-white align-items-center'>
                    <div className='col-md-5 d-md-block d-none'>
                        <img src={gifimg} className="gifimg rounded" />
                    </div>
                    <div className='col-md-7 px-md-0 px-4'>
                        <h1 className="titletext t ext-center">Contact Us</h1> 
                        {/* <iframe src="https://docs.google.com/forms/d/e/1FAIpQLScRV1yNKyAUD-7X24ZYo_lK0-vmMjsWXnVyQwgb89dGMuNO8w/viewform?embedded=true" width="100%" height="1100px" frameborder="0" marginheight="0" marginwidth="0">Loading…</iframe> */}
                        <form className='' action='https://docs.google.com/forms/u/0/d/e/1FAIpQLScRV1yNKyAUD-7X24ZYo_lK0-vmMjsWXnVyQwgb89dGMuNO8w/formResponse'>
                            <div className="form-group">
                                <input type="text" className="form-control my-4" placeholder="Name" name='entry.1020369711' />
                                <input type="text" className="form-control my-4" placeholder="Phone Number" name='entry.1125846995' />
                                <input type="email" className="form-control my-4" placeholder="Email Address" name='entry.235436795' />
                                <input type="text" className="form-control my-4" placeholder="Write your message here" name='entry.1377592063' />
                            </div>
                            <button type="submit" className="submitbtn">Submit</button>
                        </form>
                    </div>
                </div>
            </div>
            <hr />
            <div className="text-center text-white ">
                <a href="https://twitter.com/LazyLeopardClub" target="_blank"><i className="fab fa-twitter mx-2 py-3 icons"></i></a>
                <a href="https://discord.gg/kPAZkJpZsA" target="_blank"><i className="fab fa-discord mx-2 py-3 icons"></i></a>
                <a href="https://www.instagram.com/lazyleopardclub/ " target="_blank"><i className="fab fa-instagram mx-2 py-3 icons"></i></a>
                <small className="d-block pb-2">© 2022 <a href="https://www.fiverr.com/share/vzY2RA">- Developed by Sabirpro</a></small>
            </div>
        </div>
    );
}
export default Contact;