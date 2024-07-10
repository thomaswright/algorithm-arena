import React, { useEffect } from "react";
import { marked } from "marked";

let repos = [
  "weekly-challenge-1-stockfish-chess",
  "weekly-challenge-2-double-lines",
  "weekly-challenge-3-bouncy-form",
  "weekly-challenge-4-encrypted-thread",
  "weekly-challenge-5-copy-pasta",
  "weekly-challenge-6-pretty-shape",
  "weekly-challenge-7-scores-timeline",
  "weekly-challenge-8-ultimate-tic-tac-toe",
  "weekly-challenge-9-dragon-ball",
  "weekly-challenge-10-password-generator",
  "weekly-challenge-11-mini-code-golf",
  "weekly-challenge-12-fools-cursor",
  "weekly-challenge-13-three-body-eclipse",
  "weekly-challenge-14-lightbulb-coin",
  "weekly-challenge-15-cactus-generator",
  "weekly-challenge-16-branded-qrcode",
  "weekly-challenge-17-karaoke-box",
  "weekly-challenge-18-vc-simulator",
  "weekly-challenge-19-falling-breakout",
  "weekly-challenge-20-extravagant-button",
  "weekly-challenge-21-unconventional-clock",
  "weekly-challenge-22-concert-effects",
  "weekly-challenge-23-unconventional-randomness",
  "weekly-challenge-24-stairs-animations",
  "weekly-challenge-25-grid-group",
  "weekly-challenge-26-loser-tournament",
];

const main = () => {
  let [readmes, setReadmes] = React.useState(
    Array(repos.length).map((_) => null)
  );

  useEffect(() => {
    repos.map((repoName, i) => {
      let readmeUrl = `https://raw.githubusercontent.com/Algorithm-Arena/${repoName}/main/README.md`;
      let repoUrl = `https://github.com/Algorithm-Arena/${repoName}`;
      fetch(readmeUrl)
        .then((res) => res.text())
        .then((data) => {
          setReadmes((r) => {
            let n = [...r];
            n[i] = [repoUrl, data];
            return n;
          });
        });
    });
  }, []);

  let reversed = [...readmes].reverse();

  return (
    <div className="bg-slate-100 text-slate-900 min-h-screen">
      <div className="max-w-xl pt-6">
        <a
          href="https://github.com/Algorithm-Arena"
          className="text-3xl px-6 pt-6 font-black text-inherit"
        >
          {"Algorithm Arena"}
        </a>
        <div className=" px-6 py-6 font-medium ">
          {"A weekly programming challenge from "}
          <a href="https://github.com/vjeux">{"@vjeux"}</a>
        </div>

        {reversed.map((readme) => {
          if (readme) {
            let [url, content] = readme;
            let contentParsed = marked.parse(content);
            var contentDom = new DOMParser().parseFromString(
              contentParsed,
              "text/html"
            );

            const title = contentDom.querySelector("h1");
            const paragraph = contentDom.querySelector("p");

            return (
              <div key={url} className="pb-10 px-6">
                <div className="pb-2 border-b border-slate-300">
                  <a
                    href={url}
                    className="text-slate-800 text-2xl font-bold "
                    dangerouslySetInnerHTML={{ __html: title.outerHTML }}
                  />
                </div>

                <div
                  className=" pt-3"
                  dangerouslySetInnerHTML={{ __html: paragraph.outerHTML }}
                />
              </div>
            );
          } else {
            return null;
          }
        })}
      </div>
    </div>
  );
};

export default main;
