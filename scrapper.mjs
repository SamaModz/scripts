#!/usr/bin/env node

import axios from "axios";
import * as cheerio from "cheerio";

/**
 * Extrai informações de uma página usando axios + cheerio
 * @param {string} url - URL da página
 * @param {string} selector - seletor CSS (ex: "div#content h1")
 * @returns {Promise<{url: string, selector: string, results: string[]}>}
 */
async function scrape(url, selector) {
  try {
    // Faz a requisição
    const { data } = await axios.get(url);

    // Carrega no cheerio
    const $ = cheerio.load(data);

    // Captura os textos
    const results = [];
    $(selector).each((_, el) => {
      results.push($(el).text().trim());
    });

    // Retorna como JSON
    return {
      url,
      selector,
      results,
    };
  } catch (err) {
    return {
      url,
      selector,
      error: err.message,
    };
  }
}

// Exemplo de uso
(async () => {
  const data = await scrape("https://pt.aliexpress.com/item/1005006015697353.html?invitationCode=VUY5RHRBOTNTdGIvb0NsS2ZIZ0V4MTFQSDRmblpQMW54OVQ1ckpmNCtWT2VQemFTZUJrNWVWT0s1MU1hdTAyWg&srcSns=sns_Copy&sourceType=620&spreadType=socialShare&social_params=21924090788&bizType=ProductDetail&spreadCode=VUY5RHRBOTNTdGIvb0NsS2ZIZ0V4MTFQSDRmblpQMW54OVQ1ckpmNCtWT2VQemFTZUJrNWVWT0s1MU1hdTAyWg&aff_fcid=a3ec6d1f1e8649229c0bddec2f4bf875-1757104324196-03672-_mrbqdez&tt=MG&aff_fsk=_mrbqdez&aff_platform=default&sk=_mrbqdez&aff_trace_key=a3ec6d1f1e8649229c0bddec2f4bf875-1757104324196-03672-_mrbqdez&shareId=21924090788&businessType=ProductDetail&platform=AE&terminal_id=01579ed8657d471e9119407f739b66a1&afSmartRedirect=y", "div#root > div.container--container--p68zk1b:nth-of-type(2) > div.title--title--AjuTF_B.dcss-title > h1 > span");
  console.log(JSON.stringify(data, null, 2));
})();
