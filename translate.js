const axios = require("axios");
async function traduzir(text, from = "en", to = "pt") {
  const url = "https://api.mymemory.translated.net/get";

  const res = await axios.get(url, {
    params: {
      q: text,
      langpair: `${from}|${to}`
    }
  });

  return res.data.responseData.translatedText;
}

(async () => {
  const result = await traduzir("How are you?");
  console.log(result);
})();

