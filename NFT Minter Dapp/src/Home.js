import Counter from "./Counter";
import Mintbtn from "./mintbtn.js";
import gifimg from "./images/gifi.gif";
import team2 from "./images/z6.jpeg";
import team3 from "./images/z7.jpeg";
import team4 from "./images/z8.jpeg";
import Logo from "./images/logo.png";
import logo from "./images/logo.png";
// import Video from './Videos/vdo.mp4'



function Home() {
  const launchDate = new Date("Fabruary 28, 2022 00:00:00");
  const now = new Date();
  now.setMinutes(now.getMinutes() + now.getTimezoneOffset());
  let launch = now >= launchDate ? true : true;




  return (
    <div>
      <div className="container ">
        <nav className="navbar navbar-expand-lg navbar-light ">
          <a className="navbar-brand" href="/">
            <img className="navlogo" src={logo} alt="" />
          </a>
          <button
            className="navbar-toggler bg-light ml-auto"
            type="button"
            data-toggle="collapse"
            data-target="#navbarNav"
            aria-controls="navbarNav"
            aria-expanded="false"
            aria-label="Toggle navigation"
          >
            <span className="navbar-toggler-icon"></span>
          </button>

          <div className="collapse navbar-collapse " id="navbarNav">
            <ul className="navbar-nav text-center">
              <li className="nav-item active">
                <span className="px-lg-4 NavBtn  ">
                  <a href="/#home">HOME</a>
                </span>
              </li>
              <li className="nav-item ">
                <span className="px-lg-4 NavBtn ">
                  {" "}
                  <a href="/#about">ABOUT</a>
                </span>
              </li>
              <li className="nav-item">
                <span className="px-lg-4 NavBtn" href="#">
                  {" "}
                  <a href="/#Roadmap">ROADMAP</a>
                </span>
              </li>
              <li className="nav-item">
                <span className="px-lg-4 NavBtn" href="#">
                  {" "}
                  <a href="/#Team">TEAM</a>
                </span>
              </li>
              <li className="nav-item">
                <span className="px-lg-4 NavBtn" href="#">
                  {" "}
                  <a href="/#Faq">FAQ</a>
                </span>
              </li>
              <li className="nav-item">
                <span className="px-lg-4 NavBtn" href="#">
                  {" "}
                  <a href="/contact">Contact</a>
                </span>
              </li>
            </ul>
            <span className="d-block ml-auto text-center">
              <a
                href="https://twitter.com/LazyLeopardClub"
                target="_blank"
                rel="noreferrer"
              >
                <i className="fab fa-twitter mx-2 py-3 icons"></i>
              </a>
              <a
                href="https://discord.gg/kPAZkJpZsA"
                target="_blank"
                rel="noreferrer"
              >
                <i className="fab fa-discord mx-2 py-3 icons"></i>
              </a>
              <a
                href="https://www.instagram.com/lazyleopardclub/ "
                target="_blank"
                rel="noreferrer"
              >
                <i className="fab fa-instagram mx-2 py-3 icons"></i>
              </a>
            </span>
          </div>
        </nav>
      </div>

      {/* <div>
        <h1>Moralis Hello World!</h1>
        <button onClick={login}>Moralis Metamask Login</button>
        <button onClick={logOut} disabled={isAuthenticating}>Logout</button>
      </div> */}

      <div className="hero" id="home">
        <div className="pt-3 container">
          <div className="row">
            <div className="col-md-12">
              <img
                src={Logo}
                className="rounded mx-auto d-block logo"
                alt="..."
              ></img>
              {launch ? <Mintbtn /> : <Counter />}
            </div>
          </div>
        </div>
      </div>
      <div className="story py-5 container" id="about">
        <div className="row flex-md-row-reverse align-items-center">
          <div className="col-md-6">
            <div className="dz" id="one">
              <img src={gifimg} className="gifimg" alt="" />

              {/* <p><SimpleSlider /></p> */}
            </div>
            {/* <h5 className=" text-center Stext ">LLC GANG</h5> */}
          </div>
          <div className="col-md-6">
            <a id="lession2"></a>
            <h1 className="titletext">Welcome to Lazy Leopard Club</h1>
            {/* <br> */}
            {/* <br> */}
            <p className=" text-lg Post-Mint text-warning">
              Six months ago, a group of friends took a leap of faith and
              created 9999 unique leopards to integrate into the metaverse. Our
              project allows holders to gain exclusive access to an ever-growing
              community which comes with its own utilities and benefits. Having
              a Lazy leopard grants you membership access to a club whose
              benefits and offerings will increase over time. Your leopard will
              serve as a key and help open digital doors for you. Launched on
              the Ethereum blockchain, the Lazy Leopard Club aims at giving real
              life utilities back to its holders with Metaverse land acquisition
              as a key part of our roadmap, the Lazy leopard club team is here
              to stay!
            </p>
          </div>
        </div>
      </div>

      {/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<Road Map >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */}

      <div className="container Timelinee py-5">
        <div className="row Timelinee">
          <div className="col-md-12">
            <a id="Roadmap"></a>
            {/* <div className="card">
              <div className="card-body"> */}
            <h1 className="titletext text-center pb-3">Roadmap</h1>
            <div
              className="panel-group"
              id="accordion"
              role="tablist"
              aria-multiselectable="true"
            >
              <h2 className="titletext text -center py-3">Pre-mint</h2>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingOne">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseOne"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Pre-mint
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseOne"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingOne"
                >
                  <div className="panel-body">
                    <p className="">
                      $100,000 Marketing Budget. <br />
                      ETH & NFT Giveaways on socials. <br />
                      Pre-sale discount for whitelisted minters. <br />
                    </p>
                  </div>
                </div>
              </div>
              <br />
              <h2 className="titletext text -center py-3">Post-mint</h2>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingTwo">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseTwo"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Buy land and open club in Metaverse.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseTwo"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingTwo"
                >
                  <div className="panel-body">
                    <p className="">
                      After Minting is completed, our team will begin roadmap
                      activation by announcing metaverse land acquisition and
                      the commencement of the construction of the club in the
                      metaverse.
                    </p>
                  </div>
                </div>
              </div>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingThree">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseThree"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Donation towards wildlife conservation.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseThree"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingThree"
                >
                  <div className="panel-body">
                    <p className="">
                      Up to $100,000 will be donated towards the conservation of
                      endangered leopards.
                    </p>
                  </div>
                </div>
              </div>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingFour">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseFour"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Exclusive merchandise drop for all minters.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseFour"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingFour"
                >
                  <div className="panel-body">
                    <p className="">
                      Initial minters will be given access to special edition
                      merchandise.
                    </p>
                  </div>
                </div>
              </div>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingFive">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseFive"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Vote for a physical club to be opened.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseFive"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingFive"
                >
                  <div className="panel-body">
                    <p className="">
                      Holders will be given the opportunity to decide whether
                      LLC should open a club in the real world.
                    </p>
                  </div>
                </div>
              </div>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingSix">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseSix"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Dates for community events become public.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseSix"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingSix"
                >
                  <div className="panel-body">
                    <p className="">
                      Live event to be held in Dubai to meet influencers and
                      creators that made all this possible. LLC team will
                      continue marketing to raise the floor price and engage the
                      community through giveaways and events organised on
                      discord.
                    </p>
                  </div>
                </div>
              </div>
              <div className="panel panel-default">
                <div className="panel-heading" role="tab" id="RheadingSeven">
                  <h4 className="panel-title">
                    <a
                      className="collapsed"
                      role="button"
                      data-toggle="collapse"
                      data-parent="#roadmapsec"
                      href="#RcollapseSeven"
                      aria-expanded="true"
                      aria-controls="collapseOne"
                    >
                      Plans for future projects.
                    </a>
                  </h4>
                </div>
                <div
                  id="RcollapseSeven"
                  className="panel-collapse collapse in"
                  role="tabpanel"
                  aria-labelledby="RheadingSeven"
                >
                  <div className="panel-body">
                    <p className="">
                      We will then release a second drop that helps to raise the
                      value of your NFT. All holders will receive a free 3D NFT
                      as part of our second project. Royalties will be
                      reinvested back into LLC to help continue to grow the
                      project and maintain its longevity.
                    </p>
                  </div>
                </div>
              </div>
            </div>
            {/* </div>
            </div> */}
          </div>
        </div>
      </div>

      <a id="Team"></a>
      <div className="team pt-5 px-5 container">
        <div className="row">
          <div className="col-md-12">
            <h1 className="titletext text-center pb-3">Team</h1>
            <p className="text-warning text-lg Post-Mint text-center">
              LLC was founded by three young Australians with the help of a
              global hand-picked team with extensive experience in Marketing and
              Business.{" "}
            </p>
          </div>
        </div>
        <h1 className="titletext text-center pb-3">Members</h1>

        <div className="row">
          <div className="col-md-4 px-4 ">
            <img src={team4} className=" d-block mx-auto dz" id="one" />
            <h3 className="teamname pt-4">G-man</h3>
            {/* <p className="text-center text-white">Drewpeach</p> */}
          </div>
          <div className="col-md-4 px-4 mx-0 ">
            <img src={team3} className="d-block mx-auto dz" id="one" />
            <h3 className="teamname pt-4">Tommy </h3>
            {/* <p className="text-center text-white">Buck</p> */}
          </div>
          <div className="col-md-4 px-4 mx-0">
            <img src={team2} className="d-block mx-auto dz  " id="one" />
            <h3 className="teamname pt-4">Oskar</h3>
            {/* <p className="text-center text-white">Sabirpro</p> */}
          </div>
        </div>
      </div>
      <br />
      <br />
      <div className="container">
        <div className="container">
          <a id="Faq"></a>
          <div className="row">
            <div className="col-md-12">
              <div className="section-title text-center wow zoomIn mt-5">
                <h1 className="titletext text-center pb-3">
                  Frequently Asked Questions
                </h1>
                <span></span>
              </div>
            </div>
          </div>
          <div className="row">
            <div className="col-md-12">
              <div
                className="panel-group"
                id="accordion"
                role="tablist"
                aria-multiselectable="true"
              >
                <div className="panel panel-default">
                  <div className="panel-heading" role="tab" id="headingOne">
                    <h4 className="panel-title">
                      <a
                        className="collapsed"
                        role="button"
                        data-toggle="collapse"
                        data-parent="#accordion"
                        href="#collapseOne"
                        aria-expanded="true"
                        aria-controls="collapseOne"
                      >
                        How do I get whitelisted?
                      </a>
                    </h4>
                  </div>
                  <div
                    id="collapseOne"
                    className="panel-collapse collapse in"
                    role="tabpanel"
                    aria-labelledby="headingOne"
                  >
                    <div className="panel-body">
                      <p className="text-white">
                        You can get Whitelisted by following the steps on our
                        discord
                      </p>
                    </div>
                  </div>
                </div>
                <div className="panel panel-default">
                  <div className="panel-heading" role="tab" id="headingTwo">
                    <h4 className="panel-title">
                      <a
                        className="collapsed"
                        role="button"
                        data-toggle="collapse"
                        data-parent="#accordion"
                        href="#collapseTwo"
                        aria-expanded="false"
                        aria-controls="collapseTwo"
                      >
                        How can I buy a Lazy Leopard NFT?
                      </a>
                    </h4>
                  </div>
                  <div
                    id="collapseTwo"
                    className="panel-collapse collapse"
                    role="tabpanel"
                    aria-labelledby="headingTwo"
                  >
                    <div className="panel-body text-white">
                      <p>
                        You will be able to purchase a lazy Leopard NFT directly
                        on this website with Ethereum (ETH) by using the
                        MetaMask extension.
                      </p>
                    </div>
                  </div>
                </div>
                <div className="panel panel-default">
                  <div className="panel-heading" role="tab" id="headingThree">
                    <h4 className="panel-title">
                      <a
                        className="collapsed"
                        role="button"
                        data-toggle="collapse"
                        data-parent="#accordion"
                        href="#collapseThree"
                        aria-expanded="false"
                        aria-controls="collapseThree"
                      >
                        What is the mint price of Lazy Leopard NFT ?
                      </a>
                    </h4>
                  </div>
                  <div
                    id="collapseThree"
                    className="panel-collapse collapse"
                    role="tabpanel"
                    aria-labelledby="headingThree"
                  >
                    <div className="panel-body text-white">
                      <p>
                        Our Pre-Sale mint price is 0.06 ETH + gas fees per NFT.
                        Our Whitelisted members will be allowed to mint two
                        NFTs.
                      </p>
                    </div>
                  </div>
                </div>
                <div className="panel panel-default">
                  <div className="panel-heading" role="tab" id="headingFour">
                    <h4 className="panel-title text-white">
                      <a
                        className="collapsed"
                        role="button"
                        data-toggle="collapse"
                        data-parent="#accordion"
                        href="#collapseFour"
                        aria-expanded="false"
                        aria-controls="collapseFour"
                      >
                        How long after minting will my NFT be revealed?
                      </a>
                    </h4>
                  </div>
                  <div
                    id="collapseFour"
                    className="panel-collapse collapse"
                    role="tabpanel"
                    aria-labelledby="headingFour"
                  >
                    <div className="panel-body text-white">
                      <p>The reveal will be 5 days after launch. </p>
                    </div>
                  </div>
                </div>
                <div className="panel panel-default">
                  <div className="panel-heading" role="tab" id="headingFive">
                    <h4 className="panel-title text-white">
                      <a
                        className="collapsed"
                        role="button"
                        data-toggle="collapse"
                        data-parent="#accordion"
                        href="#collapseFive"
                        aria-expanded="false"
                        aria-controls="collapseFive"
                      >
                        How can I contact the team?
                      </a>
                    </h4>
                  </div>
                  <div
                    id="collapseFive"
                    className="panel-collapse collapse"
                    role="tabpanel"
                    aria-labelledby="headingFive"
                  >
                    <div className="panel-body text-white">
                      <p>
                        We are all super active, you can find us on Discord and
                        Twitter and Instagram!{" "}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <hr className="mt-4 mb-2" />
      <div className="text-center text-white ">
        <a href="https://twitter.com/LazyLeopardClub" target="_blank">
          <i className="fab fa-twitter mx-2 py-3 icons"></i>
        </a>
        <a href="https://discord.gg/kPAZkJpZsA" target="_blank">
          <i className="fab fa-discord mx-2 py-3 icons"></i>
        </a>
        <a href="https://www.instagram.com/lazyleopardclub/ " target="_blank">
          <i className="fab fa-instagram mx-2 py-3 icons"></i>
        </a>
        <small className="d-block pb-2">
          © 2022
          {/* <a href="https://www.fiverr.com/share/vzY2RA">- Developed by Sabirpro</a> */}
        </small>
      </div>
    </div>
  );
}

export default Home;
