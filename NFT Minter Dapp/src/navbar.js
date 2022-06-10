import discord from './images/herobg.png'
import fb from './images/herobg.png'
import instagram from './images/herobg.png'
import twitter from './images/herobg.png'

function Navbar(){
    return(
        <div className="row mynavbar pt-3">
            <div className="col-md-6 links">
                    <a href="#home">Home</a>
                    <a href="#about">About</a>
                    <a href="#roadmap">Roadmap</a>
            </div>
            <div className="col-md-6 text-right">
                <span className="socials">
                    <a href="#"><img className='socialicon' src={discord} /></a>
                    <a href="#"><img className='socialicon' src={twitter} /></a>
                    <a href="#"><img className='socialicon' src={fb} /></a>
                    <a href="#"><img className='socialicon' src={instagram} /></a>
                </span>
            </div>
        </div>
    );
}

export default Navbar;