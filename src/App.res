// Bindings

@module("marked") external marked: string => Dom.document = "default"
@module("marked") external parseMarked: string => string = "parse"

type domParser = {parseFromString: (string, string) => Dom.document}

@new external createDomParser: unit => domParser = "DomParser"

@send external querySelector: (Dom.document, string) => Dom.element = "querySelector"

//

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
}
module RegExpUtils = {
  let escapeRE =
    "\\[\\.\\*\\+\\?\\^\\$\\{\\}\\(\\)\\|\\[\\]\\\\"->RegExp.fromStringWithFlags(~flags="g")

  let escape = s => {
    s->String.replaceRegExp(escapeRE, "\\$&")
  }

  let usernameRE = "(?<!\\/)(@([^\\s.,!?;:\\/)]+))"->RegExp.fromStringWithFlags(~flags="g")

  let getUsernames = s => {
    s->String.match(usernameRE)->Option.map(a => a->Array.keepSome)
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
    ->Option.flatMap(a => a->Array.get(0))
    ->Option.flatMap(a => a)
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
  title: Dom.element,
  challengeDescription: Dom.element,
  submissionComments: array<submissionComment>,
  url: string,
  challengeNumber: int,
}

@react.component
let make = () => {
  let (readmes, setReadmes) = React.useState(() => [])

  let readmeDetails = readmes->Array.map(readme => {
    let domParser = createDomParser()

    let contentDom = readme.content->parseMarked->domParser.parseFromString("text/html")

    let title = contentDom->querySelector("h1")
    let challengeDescription = contentDom->querySelector("p")

    let submissionComments =
      readme.content
      ->Utils.substringBetween("### Winner", "### Prizes")
      ->Option.getOr("")
      ->String.split("*")
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
          ->Option.flatMap(a => a->getGHLinks),
          videoLink: s
          ->removeGHImageTags
          ->getGHLinks,
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

  // let submissionsByUser = readmeDetails -> Array.reduce( ())
}
