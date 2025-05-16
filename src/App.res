// Types

type submissionComment = {
  url: string,
  challengeNumber: int,
  usernames: option<array<string>>,
  submissionLink: option<string>,
  commentText: string,
  videoLink: option<string>,
  imgLink: option<string>,
  rank: int,
}

type readme = {
  name: string,
  content: string,
  url: string,
  challengeNumber: int,
}

type readmeDetail = {
  title: option<Dom.element>,
  challengeDescription: option<Dom.element>,
  submissionComments: array<submissionComment>,
  url: string,
  challengeNumber: int,
}

type leaderboardItem = {
  username: string,
  submissionComments: array<submissionComment>,
  score: int,
  rankListing: string,
}

// spice is a ppx that creates json decoder / encoders
@spice
type repos = array<string>

// Bindings

@module("marked") external marked: string => string = "marked"
@module("marked") external parseMarked: string => string = "parse"

type domParser = {parseFromString: (string, string) => Dom.document}

@new external createDomParser: unit => domParser = "DOMParser"

module Attribution = {
  @react.component
  let make = () => {
    <div className="text-xs p-6">
      <span className={"font-normal text-gray-600"}> {"By "->React.string} </span>
      <a
        className="font-bold text-blue-600"
        href={"https://github.com/thomaswright/algorithm-arena"}>
        {"Thomas Wright"->React.string}
      </a>
    </div>
  }
}

module Route = {
  @module("wouter") @react.component
  external make: (~path: string, ~children: React.element) => React.element = "Route"
}

module Link = {
  @module("wouter") @react.component
  external make: (~href: string, ~children: React.element) => React.element = "Link"
}

// Utils

module SpecialCharacters = {
  let middot = "·"
  let multiplicationX = "×"
}

module Utils = {
  let substringBetween = (s, a, b) => {
    let lenA = a->String.length
    let iA = s->String.indexOf(a)
    iA == -1
      ? None
      : {
          let iB = s->String.indexOfFrom(b, iA + lenA)
          iB == -1
            ? None
            : {
                s->String.substring(~start=iA + lenA, ~end=iB)->Some
              }
        }
  }

  // a map with a reduce arg
  let mapReduceWithIndex = (arr, (mi, ri), f) => {
    let (mapResult, _) = arr->Array.reduceWithIndex((mi, ri), ((m, r), c, i) => {
      let (m2, r2) = f(m, r, c, i)

      (m2, r2)
    })
    mapResult
  }
}
module RegExpUtils = {
  let escapeRE = %re("/\[\.\*\+\?\^\$\{\}\(\)\|\[\]\\/g")

  let escape = s => {
    s->String.replaceRegExp(escapeRE, "\\$&")
  }

  let usernameRE = %re("/(?<!\/)(@([^\s.,!?;:\/)]+))/g")

  let getUsernames = s => {
    s
    ->String.match(usernameRE)
    ->Option.map(a => a->Array.keepSome->Array.map(a => a->String.substringToEnd(~start=1)))
  }

  let submissionLinkRE = link => `${(link ++ "/issues/")->escape}(\\d+)`->RegExp.fromString

  let getSubmissionLink = (s, link) => {
    s
    ->String.match(link->submissionLinkRE)
    ->Option.flatMap(a => a->Array.get(0))
    ->Option.flatMap(a => a)
  }

  let ghLinkRE = `${"https://github.com"->escape}[^\\s\\)]*`->RegExp.fromStringWithFlags(~flags="g")

  let getGHLinks = s => {
    s
    ->String.match(ghLinkRE)
    ->Option.map(a => a->Array.keepSome)
  }

  let removeGHLinks = s => {
    s->String.replaceRegExp(ghLinkRE, "")
  }

  let ghImageTagsRE =
    `!\\[([^\\]]+)\\]\\(${"https://github.com"->escape}([^\\)]+)\\)`->RegExp.fromStringWithFlags(
      ~flags="g",
    )

  let getGHImageTags = s => {
    s
    ->String.match(ghImageTagsRE)
    ->Option.flatMap(a => a->Array.get(0))
    ->Option.flatMap(a => a)
  }

  let removeGHImageTags = s => {
    s->String.replaceRegExp(ghImageTagsRE, "")
  }
}

// Main

let routeBase = "/algorithm-arena"

let repoListGistUrl = "https://gist.githubusercontent.com/thomaswright/06e827401a84cd949997b56de8a0e345/raw/algorithm-arena-repos.json"

let medalStyles: array<JsxDOMStyle.t> = [
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
  {
    backgroundColor: `oklch(0.95 0 75)`,
    color: `oklch(0.5 0 75)`,
    borderColor: `oklch(0.6 0 75)`,
  },
]

let placeNames = ["1st", "2nd", "3rd"]

module SubmissionList = {
  @react.component
  let make = (
    ~submissions: array<submissionComment>,
    ~index,
    ~username as _,
    ~set: submissionComment => unit,
    ~remove,
    ~activeChallenge: option<int>,
  ) => {
    <div
      className="my-1 mx-1 flex flex-row gap-1 px-2 rounded items-center flex-wrap min-w-20 max-w-32"
      style={medalStyles[index]->Option.getOr({})}>
      {submissions
      ->Array.mapWithIndex((submission, i) => {
        <div
          key={submission.submissionLink->Option.getOr(i->Int.toString)}
          className=" w-fit text-sm font-bold cursor-pointer"
          onClick={_ => {
            switch (activeChallenge, submission.challengeNumber) {
            | (Some(a), s) => a == s ? remove() : set(submission)
            | _ => set(submission)
            }
          }}>
          <span className="text-inherit">
            {("#" ++ submission.challengeNumber->Int.toString)->React.string}
          </span>
        </div>
      })
      ->React.array}
    </div>
  }
}

module Winner = {
  @react.component
  let make = (~url as _, ~winner, ~active, ~set, ~remove) => {
    <div
      className="border rounded-full w-fit px-3 py-1 font-bold flex flex-row flex-wrap cursor-pointer"
      style={medalStyles[winner.rank]->Option.getOr({})}
      onClick={_ => {
        active ? remove() : set()
      }}>
      {placeNames[winner.rank]->Option.mapOr(React.null, p =>
        <span className="pr-1"> {p->React.string} </span>
      )}
      {winner.usernames->Option.mapOr(React.null, u =>
        <span className="text-inherit">
          {u
          ->Array.map(username => {
            "@" ++ username
          })
          ->Array.join(" ")
          ->React.string}
        </span>
      )}
    </div>
  }
}

module CommentDetails = {
  @react.component
  let make = (~comments, ~close) => {
    <div className="p-4 pt-2 border border-slate-300 rounded-xl mt-1 max-w-xl relative">
      <div className=" absolute right-2 top-0 cursor-pointer" onClick={_ => close()}>
        {SpecialCharacters.multiplicationX->React.string}
      </div>
      <div
        className="pb-2"
        dangerouslySetInnerHTML={{
          "__html": marked(comments.commentText),
        }}
      />
      <div className="flex flex-row justify-between">
        {comments.submissionLink->Option.mapOr(React.null, v =>
          <a href={v}> {"Submission"->React.string} </a>
        )}
        <a href={comments.url}>
          {("Challenge #" ++ comments.challengeNumber->Int.toString)->React.string}
        </a>
      </div>
      {comments.videoLink->Option.mapOr(React.null, v =>
        <div className="max-w-xl">
          <video className="pt-2" autoPlay={true} src={v} />
        </div>
      )}
      {comments.imgLink->Option.mapOr(React.null, v =>
        <div className="max-w-xl">
          <img className="pt-2" src={v} />
        </div>
      )}
    </div>
  }
}

@react.component
let make = () => {
  let (readmes, setReadmes) = React.useState(() => Belt.Map.String.empty)
  let (commentsPerChallenge, setCommentsPerChallenge) = React.useState(() => Belt.Map.String.empty)
  let (
    commentsPerUser: Belt.Map.String.t<submissionComment>,
    setCommentsPerUser,
  ) = React.useState(() => Belt.Map.String.empty)

  React.useEffect0(() => {
    Dom.Storage2.localStorage
    ->Dom.Storage2.getItem("path")
    ->Option.forEach(path => {
      Dom.Storage2.localStorage->Dom.Storage2.removeItem("path")
      RescriptReactRouter.push(path)
    })
    None
  })

  React.useEffect0(() => {
    Webapi.Fetch.fetch(repoListGistUrl)
    ->Promise.then(res => res->Webapi.Fetch.Response.json)
    ->Promise.then(json =>
      json
      ->repos_decode
      ->Promise.resolve
    )
    ->Promise.then(arr => {
      arr
      ->Result.getOr([])
      ->Array.filter(name => name->String.includes("weekly-challenge"))
      ->Array.map(
        name => {
          let challengeNumber =
            name
            ->String.split("-")
            ->Array.get(2)
            ->Option.flatMap(a => a->Int.fromString)
            ->Option.getOr(0)

          let readmeUrl = `https://raw.githubusercontent.com/Algorithm-Arena/${name}/main/README.md`
          let repoUrl = `https://github.com/Algorithm-Arena/${name}`
          Webapi.Fetch.fetch(readmeUrl)
          ->Promise.then(res => res->Webapi.Fetch.Response.text)
          ->Promise.then(
            content => {
              setReadmes(
                r => {
                  r->Belt.Map.String.set(
                    name,
                    {
                      name,
                      content,
                      url: repoUrl,
                      challengeNumber,
                    },
                  )
                },
              )->Promise.resolve
            },
          )
        },
      )
      ->Promise.resolve
    })
    ->ignore
    None
  })

  let readmeDetails =
    readmes
    ->Belt.Map.String.valuesToArray
    ->Array.map(readme => {
      let domParser = createDomParser()

      let contentDom = readme.content->parseMarked->domParser.parseFromString("text/html")

      let title = contentDom->Webapi.Dom.Document.querySelector("h1")
      let challengeDescription = contentDom->Webapi.Dom.Document.querySelector("p")

      let submissionComments =
        readme.content
        ->Utils.substringBetween("### Winner", "### Prizes")
        ->Option.getOr("")
        ->String.split("*")
        ->Array.filterWithIndex((_, i) => i > 0)
        ->Array.mapWithIndex((s, i) => {
          open RegExpUtils

          {
            url: readme.url,
            challengeNumber: readme.challengeNumber,
            rank: readme.challengeNumber == 2 ? 0 : i,
            usernames: s->getUsernames,
            submissionLink: s->getSubmissionLink(readme.url),
            imgLink: s
            ->getGHImageTags
            ->Option.flatMap(a => a->getGHLinks)
            ->Option.flatMap(a => a->Array.get(0)),
            videoLink: s
            ->removeGHImageTags
            ->getGHLinks
            ->Option.flatMap(a => a->Array.get(1)),
            commentText: s->removeGHImageTags->removeGHLinks,
          }
        })

      {
        title,
        challengeDescription,
        submissionComments,
        url: readme.url,
        challengeNumber: readme.challengeNumber,
      }
    })
    ->Array.toSorted(({challengeNumber: a}, {challengeNumber: b}) => (b - a)->Int.toFloat)

  let submissionsByUser = readmeDetails->Array.reduce(Belt.Map.String.empty, (acc, cur) => {
    cur.submissionComments->Array.reduce(acc, (acc2, cur2) => {
      cur2.usernames
      ->Option.getOr([])
      ->Array.reduce(
        acc2,
        (acc3, username) => {
          acc3->Belt.Map.String.updateU(
            username,
            v => v->Option.mapOr([cur2], w => [...w, cur2])->Some,
          )
        },
      )
    })
  })

  let leaderboard =
    submissionsByUser
    ->Belt.Map.String.toArray
    ->Array.map(((username, submissionComments)) => {
      let score = submissionComments->Array.reduce(0, (totalScore, {rank}) => {
        totalScore + (rank === 0 ? 5 : rank === 1 ? 4 : rank === 2 ? 3 : 1)
      })

      (
        {
          username,
          submissionComments,
          score,
          rankListing: SpecialCharacters.middot,
        }: leaderboardItem
      )
    })
    ->Array.toSorted((
      {score: aScore, username: aUsername},
      {score: bScore, username: bUsername},
    ) => {
      bScore == aScore ? String.localeCompare(aUsername, bUsername) : (bScore - aScore)->Int.toFloat
    })
    ->{
      Utils.mapReduceWithIndex(([], (-1, 0)), (m, (lastScore, lastRank), cur, i) => {
        let isSameScore = cur.score === lastScore

        (
          [
            ...m,
            {
              ...cur,
              rankListing: isSameScore ? SpecialCharacters.middot : (i + 1)->Int.toString,
            },
          ],
          (cur.score, isSameScore ? lastRank : i),
        )
      })
    }

  <div className="bg-slate-100 text-slate-900 min-h-screen">
    <div className=" pt-6" />
    <a
      href="https://github.com/Algorithm-Arena"
      className="text-3xl px-6 pt-6 pb-3 font-black text-inherit">
      {"Algorithm Arena"->React.string}
    </a>
    <div className=" px-6 pb-2 pt-3 font-medium ">
      {"A weekly programming challenge from "->React.string}
      <a href="https://github.com/vjeux"> {"@vjeux"->React.string} </a>
    </div>
    <Route path={"/algorithm-arena" ++ "/"}>
      <div className="px-6 pt-1 pb-3">
        <Link href={routeBase ++ "/leaderboard"}> {"Go to Leaderboard"->React.string} </Link>
      </div>
      <div className="max-w-xl">
        {readmeDetails
        ->Array.map(({url, submissionComments, title, challengeDescription}) => {
          let renderWinner = winner =>
            <Winner
              url
              winner
              active={commentsPerChallenge
              ->Belt.Map.String.get(url)
              ->Option.mapOr(false, v => v.submissionLink == winner.submissionLink)}
              remove={() => setCommentsPerChallenge(v => v->Belt.Map.String.remove(url))}
              set={() => setCommentsPerChallenge(v => v->Belt.Map.String.set(url, winner))}
            />

          <div key={url} className="pb-10 px-6">
            <div className="pb-2 border-b border-slate-300">
              {title->Option.mapOr(React.null, t =>
                <a
                  href={url}
                  className="text-slate-800 text-2xl font-bold "
                  dangerouslySetInnerHTML={{"__html": t->Webapi.Dom.Element.outerHTML}}
                />
              )}
            </div>
            {challengeDescription->Option.mapOr(React.null, c =>
              <div
                className=" pt-3"
                dangerouslySetInnerHTML={{
                  "__html": c->Webapi.Dom.Element.outerHTML,
                }}
              />
            )}
            <div className="flex flex-col sm:flex-row gap-3 py-2 flex-wrap">
              {submissionComments[0]->Option.mapOr(React.null, renderWinner)}
              {submissionComments[1]->Option.mapOr(React.null, renderWinner)}
              {submissionComments[2]->Option.mapOr(React.null, renderWinner)}
            </div>
            <div>
              {commentsPerChallenge
              ->Belt.Map.String.get(url)
              ->Option.mapOr(React.null, comments => {
                <CommentDetails
                  comments
                  close={() => {
                    setCommentsPerChallenge(v => v->Belt.Map.String.remove(url))
                  }}
                />
              })}
            </div>
          </div>
        })
        ->React.array}
      </div>
    </Route>
    <Route path={"/algorithm-arena" ++ "/leaderboard"}>
      <div className={"px-6 pt-1 pb-3"}>
        <Link href={routeBase ++ "/"}> {"Go to Challenges"->React.string} </Link>
      </div>
      <div className="pb-10">
        <div className="px-6 pb-2 font-bold text-2xl"> {"Leaderboard"->React.string} </div>
        <div className="px-6 pb-2  text-xs font-medium">
          {"5 points for 1st, 4 for 2nd, 3 for 3rd, and 1 for any other submission"->React.string}
        </div>
        <div className="px-6 pt-1 overflow-x-scroll ">
          <table key={"leaderboard-table"}>
            <thead>
              <tr className="text-sm ">
                <th className=" text-left px-2 "> {React.null} </th>
                <th className=" text-left  border-r"> {"User"->React.string} </th>
                <th className=" text-left px-2 border-r"> {"Score"->React.string} </th>
                <th className=" text-left px-2 border-r"> {"1st Place"->React.string} </th>
                <th className=" text-left px-2 border-r"> {"2nd Place"->React.string} </th>
                <th className=" text-left px-2 border-r"> {"3rd Place"->React.string} </th>
                <th className=" text-left px-2"> {"Other"->React.string} </th>
              </tr>
            </thead>
            <tbody>
              {leaderboard
              ->Array.map(({username, submissionComments, score, rankListing}) => {
                let (s1, s2, s3, shm) = submissionComments->Array.reduce(([], [], [], []), (
                  (p1, p2, p3, hm),
                  cur,
                ) => {
                  switch cur.rank {
                  | 0 => ([...p1, cur], p2, p3, hm)
                  | 1 => (p1, [...p2, cur], p3, hm)
                  | 2 => (p1, p2, [...p3, cur], hm)
                  | _ => (p1, p2, p3, [...hm, cur])
                  }
                })

                let renderSubmissionList = (index, submissions) =>
                  <SubmissionList
                    username={username}
                    activeChallenge={commentsPerUser
                    ->Belt.Map.String.get(username)
                    ->Option.map(v => v.challengeNumber)}
                    set={comment =>
                      setCommentsPerUser(v => v->Belt.Map.String.set(username, comment))}
                    remove={() => setCommentsPerUser(v => v->Belt.Map.String.remove(username))}
                    submissions
                    index
                  />

                score == 0
                  ? React.null
                  : <React.Fragment key={username}>
                      <tr key={username ++ "_submissions"} className="divide-y ">
                        <td>
                          <div className="font-bold text-sm pr-2 text-slate-400 text-center">
                            {rankListing->React.string}
                          </div>
                        </td>
                        <td>
                          <div className="py-1 pr-2 flex ">
                            <a
                              href={"https://github.com/" ++ username}
                              className="text-inherit col-span-2 text-right ">
                              {("@" ++ username)->React.string}
                            </a>
                          </div>
                        </td>
                        <td>
                          <div className="font-bold text-sm px-2">
                            {score->Int.toString->React.string}
                          </div>
                        </td>
                        <td> {renderSubmissionList(0, s1)} </td>
                        <td> {renderSubmissionList(1, s2)} </td>
                        <td> {renderSubmissionList(2, s3)} </td>
                        <td> {renderSubmissionList(3, shm)} </td>
                      </tr>
                      {commentsPerUser
                      ->Belt.Map.String.get(username)
                      ->Option.mapOr(React.null, v =>
                        <tr key={username ++ "_comments"}>
                          <td />
                          <td colSpan={6}>
                            <CommentDetails
                              comments={v}
                              close={() => {
                                setCommentsPerUser(v => v->Belt.Map.String.remove(username))
                              }}
                            />
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
              })
              ->React.array}
            </tbody>
          </table>
        </div>
      </div>
    </Route>
    <Attribution />
  </div>
}

let default = make
