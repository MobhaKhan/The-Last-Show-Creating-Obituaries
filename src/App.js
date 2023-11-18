import React, { useState, useEffect } from "react";
import Overlay from "./Overlay";
import FormattedDate from "./FormattedDate"

function App() {
  const [showOverlay, setShowOverlay] = useState(false);
  const [obituaries, setObituaries] = useState([]);
  const [playAudio, setPlayAudio] = useState(false);
  const [collapse, setCollapse] = useState({});

  // useEffect(() => {
  //   const asyncEffect = async () => {
  //     const promise = await fetch("https://r3fjnelbbimkhnypfrjnzo2l3e0udaer.lambda-url.ca-central-1.on.aws/"); //Get obituary url
  //     const res = await promise.json();
  //     setObituaries(res);
  //   };
  //   asyncEffect();
  // }, []);

  useEffect(() => {
    const asyncEffect = async () => {
      const promise = await fetch("https://r3fjnelbbimkhnypfrjnzo2l3e0udaer.lambda-url.ca-central-1.on.aws/"); //Get obituary url
      const res = await promise.json();
      setObituaries(res);
      setCollapse(res.reduce((acc, cur) => {
        acc[cur.id] = true;
        return acc;
      }, {}));
    };
    asyncEffect();
  }, []);

  const handleClick = () => {
    setShowOverlay(true);
  };

  const handleClose = () => {
    setShowOverlay(false);
  };

  const handleObituarySubmit = (obituary) => {
    setObituaries([...obituaries, obituary]);
  };

  const handlePlayPause = (obituary) => {
    const audio = document.getElementById(`audio-${obituary.id}`);
        if (audio.paused) {
          audio.play();
          setPlayAudio(obituary.id);
        } else {
          audio.pause();
          setPlayAudio(false);
        }
  };

  const handleCollapse = (obituaryId) => {
    setCollapse((prevState) => {
      const newState = { ...prevState };
      newState[obituaryId] = !newState[obituaryId];
      return newState;
    });
  };
 
  return (
    <div id="container">
      <header>
        <aside>&nbsp;</aside>
        <div id="app-header">
          <h1>The Last Show</h1>
        </div>
        <aside>
          <button id="header-button" onClick={handleClick}>
            <h4>+ New Obituary</h4>
          </button>
        </aside>
      </header>
      {showOverlay && (
        <Overlay
        onClose={handleClose}
        onObituarySubmit={handleObituarySubmit}
        />
      )}
      <div id="main-container">
        {obituaries.length > 0 ? (
          <div className="obituary-grid">
            {obituaries.map((obituary) => (
              <div id="obituary-container" key={obituary.id}>
                <img 
                  src={obituary["cloud_img"]} 
                  alt="profile" 
                  style={{ maxWidth: "100%" }} 
                  onClick={() => handleCollapse(obituary.id)} 
                /> <br/>
                <p><b>{obituary["name"]}</b></p>
                <small><FormattedDate label="Born" date={obituary["born_year"]} /> - <FormattedDate label="Died" date={obituary["died_year"]} /></small>
                {!collapse[obituary.id] && (
                  <>
                  <br/><p id="obituary-text">{obituary["chatgpt"]}</p><br/>
                  <div className="audio-container">
                    <audio
                      id={`audio-${obituary.id}`}
                      src={obituary["voice_resp"]}
                      type="audio/mp3"
                    />
                    <button
                      className="play-pause-button"
                      onClick={() => handlePlayPause(obituary)}
                    >
                      {playAudio === obituary.id ? (
                        <span className="pause-icon">&#10074;&#10074;</span>
                      ) : (
                        <span className="play-icon">&#9658;</span>
                      )}
                    </button>
                  </div>
                  </>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div id="empty-container">
            <h5>No Obituary Yet</h5>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;