import React, { useEffect } from "react";
import { marked } from "marked";
function isEmptyObject(obj) {
  return Object.keys(obj).length === 0;
}

function objectValues(obj) {
  return Object.keys(obj).map((key) => {
    return obj[key];
  });
}

const main = () => {
  let [readmes, setReadmes] = React.useState({});

  useEffect(() => {
    fetch("https://api.github.com/orgs/Algorithm-Arena/repos")
      .then((res) => res.json())
      .then((data) => {
        data
          .filter(({ name }) => {
            return name.includes("weekly-challenge");
          })
          .map(({ name }) => {
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
      });
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
        })}
      </div>
    </div>
  );
};

export default main;
