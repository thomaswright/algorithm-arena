import React, { useEffect } from "react";
import { marked } from "marked";

let staticRepoList = [
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
].map((name) => ({ name }));

function isEmptyObject(obj) {
  return Object.keys(obj).length === 0;
}

function objectValues(obj) {
  return Object.keys(obj).map((key) => {
    return obj[key];
  });
}

function substringBetween(mainString, substringA, substringB) {
  let indexA = mainString.indexOf(substringA);
  if (indexA === -1) return "";

  let indexB = mainString.indexOf(substringB, indexA + substringA.length);
  if (indexB === -1) return "";

  return mainString.substring(indexA + substringA.length, indexB);
}

function getFirstUsername(str) {
  const regex = /@([^\s.,!?;:]+)/;
  const match = str.match(regex);

  return match ? match[1] : null;
}

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function getSubmissionLinkByLink(str, link) {
  const escaped = escapeRegExp(link + "/issues/");
  const regex = new RegExp(`${escaped}(\\d+)`, "i");
  const match = str.match(regex);
  return match ? match[0] : null;
}

let medalStyles = [
  {
    backgroundColor: `oklch(0.95 0.1 95)`,
    color: `oklch(0.5 0.2 95)`,
    borderColor: `oklch(0.6 0.2 95)`,
  },
  {
    backgroundColor: `oklch(0.95 0.05 250)`,
    color: `oklch(0.5  0.05 250)`,
    borderColor: `oklch(0.6  0.05 250)`,
  },
  {
    backgroundColor: `oklch(0.95 0.05 75)`,
    color: `oklch(0.5 0.1 75)`,
    borderColor: `oklch(0.6 0.1 75)`,
  },
];

let places = ["1st", "2nd", "3rd"];

const Winner = ({ winnerList, index }) => {
  let winner = winnerList[index];
  return winner !== undefined ? (
    <div
      className="border rounded-full w-fit px-3 py-1 font-bold"
      style={index < 3 ? medalStyles[index] : {}}
    >
      <span className="pr-1">{index < 3 ? places[index] : ""}</span>
      <a href={winner.submissionLink} className="text-inherit">
        {"@" + winner.username}
      </a>
    </div>
  ) : null;
};

const main = () => {
  let [readmes, setReadmes] = React.useState({});

  useEffect(() => {
    let fetchRepoReadmes = (repoList) =>
      repoList.map(({ name }) => {
        let repoNumber = name.split("-")[2];
        let readmeUrl = `https://raw.githubusercontent.com/Algorithm-Arena/${name}/main/README.md`;
        let repoUrl = `https://github.com/Algorithm-Arena/${name}`;
        fetch(readmeUrl)
          .then((res) => res.text())
          .then((data) => {
            setReadmes((r) => {
              return {
                ...r,
                [name]: {
                  name: name,
                  content: data,
                  url: repoUrl,
                  num: repoNumber,
                },
              };
            });
          });
      });

    fetchRepoReadmes(staticRepoList);

    // dynamic fetch of repos will get rate limited
    // fetch("https://api.github.com/orgs/Algorithm-Arena/repos")
    //   .then((res) => res.json())
    //   .then((data) => {
    //     fetchRepoReadmes(
    //       data.filter(({ name }) => {
    //         return name.includes("weekly-challenge");
    //       })
    //     );
    //   });
  }, []);

  let sorted = isEmptyObject(readmes)
    ? []
    : objectValues(readmes).sort(({ num: a }, { num: b }) => b - a);

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

        {sorted.map(({ content, url }) => {
          let contentParsed = marked.parse(content);
          var contentDom = new DOMParser().parseFromString(
            contentParsed,
            "text/html"
          );

          const title = contentDom.querySelector("h1");
          const paragraph = contentDom.querySelector("p");

          const winnerList = substringBetween(
            content,
            "### Winner",
            "### Prizes"
          )
            .split("*")
            .map((li) => {
              return {
                username: getFirstUsername(li),
                submissionLink: getSubmissionLinkByLink(li, url),
              };
            })
            .filter(({ username }) => username !== null);

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
              <div className="flex flex-row gap-3 py-2">
                <Winner winnerList={winnerList} index={0} />
                <Winner winnerList={winnerList} index={1} />
                <Winner winnerList={winnerList} index={2} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default main;
