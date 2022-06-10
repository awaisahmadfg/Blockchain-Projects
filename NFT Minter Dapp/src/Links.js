import logo from './images/logo.png'

import React from "react";


function Links(){
    return(
        <div>
            <div className='container linksection'>
                <div className='row py-3 text-white align-items-center'>
                    <div className='col-md-12 px-md-0 px-4'>
                        <img src={logo} className="rounded mx-auto d-block logo" alt="..."></img>
                        <h1 className="titletext text-center mb-5">Lazy Leopard Club</h1>

                        <div className='linkbtns'>
                            <a href="https://twitter.com/LazyLeopardClub" target="_blank" className='btn btn-light text-black d-block my-2'><i className="fab fa-twitter mx-2 "></i> Twitter</a>
                            <a href="https://discord.gg/kPAZkJpZsA" target="_blank" className='btn btn-light text-black d-block my-2'><i className="fab fa-discord mx-2"></i> Discord</a>
                            <a href="https://www.instagram.com/lazyleopardclub/" target="_blank" className='btn btn-light text-black d-block my-2'><i className="fab fa-instagram mx-2"></i> Instagram</a>
                            <a href="https://www.lazyleopardclub.com/" target="_blank" className='btn btn-light text-black d-block my-2'><i className="fas fa-globe mx-2"></i> Website</a>
                            {/* <a href="#" target="_blank" className='btn btn-light text-black d-block my-2 disabled' >Opensea</a>
                            <a href="#" target="_blank" className='btn btn-light text-black d-block my-2 disabled' >Rarible - NFT Marketplace</a> */}
                        </div>
                    </div>
                </div>
            </div>
            <hr />
            <div className="text-center text-white ">
                <small className="d-block pb-2">© 2022 <a href="https://www.fiverr.com/share/vzY2RA">- Developed by Sabirpro</a></small>
            </div>
        </div>
    );
}
export default Links;