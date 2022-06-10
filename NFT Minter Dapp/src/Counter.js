import { useEffect, useState } from "react";
import './counter.css';

function Counter() {
  const [days, setDays] = useState(0);
  const [hours, setHours] = useState(0);
  const [minutes, setMinutes] = useState(0);
  const [seconds, setSeconds] = useState(0);
  const [loading, setLoading] = useState(true);

  const countDown = () => {
    const endDate = new Date("Feb 28, 2022 20:00:00").getTime();
    let today = new Date();
    today.setMinutes(today.getMinutes() + today.getTimezoneOffset());
    today = today.getTime();
    const timeDiff = endDate - today;

    const s = 1000;
    const m = s * 60;
    const h = m * 60;
    const d = h * 24;

    let timeDays = Math.floor(timeDiff / d);
    let timeHours = Math.floor((timeDiff % d) / h);
    let timeMinutes = Math.floor((timeDiff % h) / m);
    let timeSeconds = Math.floor((timeDiff % m) / s);

    timeDays = timeDays < 1 ? 0 : timeDays;
    timeHours = timeHours < 1 ? 0 : timeHours;
    timeMinutes = timeMinutes < 1 ? 0 : timeMinutes;
    timeSeconds = timeSeconds < 1 ? 0 : timeSeconds;

    timeDays = timeDays < 10 ? "0" + timeDays : timeDays;
    timeHours = timeHours < 10 ? "0" + timeHours : timeHours;
    timeMinutes = timeMinutes < 10 ? "0" + timeMinutes : timeMinutes;
    timeSeconds = timeSeconds < 10 ? "0" + timeSeconds : timeSeconds;

    setDays(timeDays);
    setHours(timeHours);
    setMinutes(timeMinutes);
    setSeconds(timeSeconds);
  };

  useEffect(() => {
    const id = setInterval(countDown, 1000);
    setLoading(false);

    return () => clearInterval(id);
  }, []);

  return (
    <>
      {loading ? (
        <div className="loading">
          <div className="spinner"></div>
        </div>
      ) : (
        <section className="counter-color ">
          <div className="counter-container container-fluid py-5 px-0">
            <div className="countdown">
              <article> 
                <p className="D">{days}</p>
                <h3 className="d">Days</h3>
              </article>
              <article>
                <p>{hours}</p>
                <h3 className="d">Hours</h3>
              </article>
              <article>
                <p>{minutes}</p>
                <h3 className="d" >Minutes</h3>
              </article>
              <article>
                <p>{seconds}</p>
                <h3 className="d">Seconds</h3>
              </article>
            </div>
          </div>
        </section>
      )}
    </>
  );
}

export default Counter;
