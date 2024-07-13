import React, { useEffect } from "react";
import { marked } from "marked";
import { Link, Route, useLocation } from "wouter";

let routeBase = "/algorithm-arena";

let repoListGistUrl =
  "https://gist.githubusercontent.com/thomaswright/06e827401a84cd949997b56de8a0e345/raw/6c91045fc9acb0f25f04a75d9062f8947d7cddfd/algorithm-arena-repos.json";

function isEmptyObject(obj) {
  return Object.keys(obj).length === 0;
}

function objectValues(obj) {
  return Object.keys(obj).map((key) => {
    return obj[key];
  });
}

function updateArray(arr, index, f) {
  let newArr = [...arr];

  if (index >= 0 && index < newArr.length) {
    newArr[index] = f(newArr[index]);
  } else {
    console.error("Index out of bounds");
  }

  return newArr;
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

const SubmissionList = ({ submissionLinks, index }) => {
  let submissions = submissionLinks[index];
  return (
    <div
      className="flex flex-row gap-1 px-2 mx-1 rounded items-center flex-wrap min-w-20"
      style={index < 3 ? medalStyles[index] : {}}
    >
      {submissions.map(({ challengeNumber, submissionLink }) => {
        {
          return (
            <div className=" w-fit text-sm font-bold">
              <a href={submissionLink} className="text-inherit">
                {"#" + challengeNumber}
              </a>
            </div>
          );
        }
      })}
    </div>
  );
};

const main = () => {
  let [readmes, setReadmes] = React.useState({});
  const [location, setLocation] = useLocation();

  useEffect(() => {
    let path = localStorage.getItem("path");
    if (path) {
      localStorage.removeItem("path");
      setLocation([path]);
    }
  }, []);

  useEffect(() => {
    let fetchRepoReadmes = (repoList) =>
      repoList.map((name) => {
        let challengeNumber = name.split("-")[2];
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
                  challengeNumber: challengeNumber,
                },
              };
            });
          });
      });

    // fetchRepoReadmes(staticRepoList);

    fetch(repoListGistUrl)
      .then((res) => res.json())
      .then((data) => {
        fetchRepoReadmes(
          data.filter((name) => {
            return name.includes("weekly-challenge");
          })
        );
      });
  }, []);

  let sorted = isEmptyObject(readmes)
    ? []
    : objectValues(readmes).sort(({ num: a }, { num: b }) => b - a);

  let details = sorted.map(({ content, url, challengeNumber }) => {
    let contentParsed = marked.parse(content);
    var contentDom = new DOMParser().parseFromString(
      contentParsed,
      "text/html"
    );

    const title = contentDom.querySelector("h1");
    const paragraph = contentDom.querySelector("p");

    const winnerList = substringBetween(content, "### Winner", "### Prizes")
      .split("*")
      .map((li) => {
        return {
          username: getFirstUsername(li),
          submissionLink: getSubmissionLinkByLink(li, url),
        };
      })
      .filter(({ username }) => username !== null);

    return {
      challengeNumber,
      url,
      title,
      paragraph,
      winnerList,
    };
  });

  let submissionsByUser = details.reduce((acc, cur) => {
    return cur.winnerList.reduce((acc2, cur2, i) => {
      return {
        ...acc2,
        [cur2.username]: [
          ...(acc2[cur2.username] ? acc2[cur2.username] : []),
          {
            rank: i,
            submissionLink: cur2.submissionLink,
            challengeNumber: cur.challengeNumber,
          },
        ],
      };
    }, acc);
  }, {});

  let leaderBoard = Object.keys(submissionsByUser)
    .map((username) => {
      let submissions = submissionsByUser[username];
      let score = submissions.reduce((totalScore, { rank }) => {
        let scoreInc = rank === 0 ? 3 : rank === 1 ? 2 : rank === 2 ? 1 : 0;
        return totalScore + scoreInc;
      }, 0);

      return {
        username,
        submissions,
        score,
      };
    })
    .sort(({ score: a }, { score: b }) => b - a);

  return (
    <div className="bg-slate-100 text-slate-900 min-h-screen">
      <div className="max-w-xl pt-6">
        <a
          href="https://github.com/Algorithm-Arena"
          className="text-3xl px-6 pt-6 pb-3 font-black text-inherit"
        >
          {"Algorithm Arena"}
        </a>
        <div className=" px-6 pb-2 pt-3 font-medium ">
          {"A weekly programming challenge from "}
          <a href="https://github.com/vjeux">{"@vjeux"}</a>
        </div>
        <Route path={"/algorithm-arena" + "/"}>
          <Link href={routeBase + "/leaderboard"}>
            <div className={"px-6 pt-1 pb-3"}>{"Go to Leaderboard"}</div>
          </Link>
          {details.map(({ url, winnerList, title, paragraph }) => {
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
        </Route>
        <Route path={"/algorithm-arena" + "/leaderboard"}>
          <Link href={routeBase + "/"}>
            <div className={"px-6 pt-1 pb-3"}>{"Go to Challenges"}</div>
          </Link>
          <div className="pb-10">
            <div className="px-6 pb-2 font-bold text-2xl">Leaderboard</div>
            <div className="px-6 pb-2  text-xs font-medium">
              {"3 points for 1st, 2 for 2nd, 1 for 3rd"}
            </div>

            <div className="px-6 pt-1">
              <table class="">
                {leaderBoard.map(({ username, submissions, score }, i) => {
                  let submissionLinks = submissions.reduce(
                    (acc, cur) => {
                      return cur.rank > 2
                        ? acc
                        : updateArray(acc, cur.rank, (s) => {
                            return [
                              ...s,
                              {
                                submissionLink: cur.submissionLink,
                                challengeNumber: cur.challengeNumber,
                              },
                            ];
                          });
                    },
                    [[], [], []]
                  );
                  return score === 0 ? null : (
                    <tr className="divide-y ">
                      <td>
                        <div className="font-bold text-sm pr-2 text-slate-400">
                          {i + 1}
                        </div>
                      </td>
                      <td>
                        <div className="py-1 pr-2 flex ">
                          <a
                            href={"https://github.com/" + username}
                            className="text-inherit col-span-2 text-right "
                          >
                            {"@" + username}
                          </a>
                        </div>
                      </td>
                      <td>
                        <div className="font-bold text-sm px-2">{score}</div>
                      </td>
                      <td>
                        <SubmissionList
                          submissionLinks={submissionLinks}
                          index={0}
                        />
                      </td>
                      <td>
                        <SubmissionList
                          submissionLinks={submissionLinks}
                          index={1}
                        />
                      </td>
                      <td>
                        <SubmissionList
                          submissionLinks={submissionLinks}
                          index={2}
                        />
                      </td>
                    </tr>
                  );
                })}
              </table>
            </div>
          </div>
        </Route>
      </div>
    </div>
  );
};

export default main;
