const axios = require('axios');
const cheerio = require('cheerio');

/**
 * Extrai informações de um vídeo do YouTube usando axios e cheerio.
 * @param {string} url - URL do vídeo do YouTube.
 */
async function getYouTubeVideoInfo(url) {
  try {
    // 1. Obter o HTML da página do vídeo
    const response = await axios.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win 64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7'
      }
    });

    const html = response.data;
    const $ = cheerio.load(html);

    // 2. Extrair dados básicos das meta tags
    const title = $('meta[name="title"]').attr('content') || $('title').text().replace(' - YouTube', '');
    const channelName = $('link[itemprop="name"]').attr('content') || $('span[itemprop="author"] link[itemprop="name"]').attr('content');
    const publishDate = $('meta[itemprop="datePublished"]').attr('content');

    // 3. Extrair dados do objeto JSON 'ytInitialData'
    const scriptContent = $('script').filter((i, el) => $(el).html().includes('var ytInitialData =')).html();

    let views = 'N/A';
    let likes = 'N/A';
    let dislikes = 'N/A';

    if (scriptContent) {
      try {
        const jsonStr = scriptContent.split('var ytInitialData = ')[1].split(';</script>')[0];
        const data = JSON.parse(jsonStr);

        // Tentar encontrar views
        const videoPrimaryInfo = data.contents.twoColumnWatchNextResults.results.results.contents[0].videoPrimaryInfoRenderer;
        views = videoPrimaryInfo.viewCount.videoViewCountRenderer.viewCount.simpleText.replace(/[^0-9]/g, '');

        // Tentar encontrar likes
        const buttons = videoPrimaryInfo.videoActions.menuRenderer.topLevelButtons;
        const likeButton = buttons.find(b => b.segmentedLikeDislikeButtonRenderer);
        if (likeButton) {
          const likeText = likeButton.segmentedLikeDislikeButtonRenderer.likeButton.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label;
          likes = likeText.replace(/[^0-9]/g, '');
        }
      } catch (e) {
        // Fallback se o JSON mudar
        views = $('meta[itemprop="interactionCount"]').attr('content') || 'N/A';
      }
    }

    // 4. Buscar dislikes via API externa (Return YouTube Dislike)
    try {
      const videoIdMatch = url.match(/(?:v=|\/embed\/|\/1\/|\/v\/|https:\/\/youtu\.be\/)([^"&?\/\s]{11})/);
      if (videoIdMatch) {
        const videoId = videoIdMatch[1];
        const rydResponse = await axios.get(`https://returnyoutubedislikeapi.com/votes?videoId=${videoId}`);
        dislikes = rydResponse.data.dislikes;
        // Se views ou likes falharam no HTML, usamos os da API RYD como fallback
        if (views === 'N/A' || views === '0') views = rydResponse.data.viewCount;
        if (likes === 'N/A') likes = rydResponse.data.likes;
      }
    } catch (err) {
      // Silencioso se falhar
    }

    // Formatação final
    console.log(`Título:       ${title}
Canal:        ${channelName || 'Não encontrado'}
Views:        ${parseInt(views || 0).toLocaleString('pt-BR')}
Likes:        ${likes !== 'N/A' ? parseInt(likes).toLocaleString('pt-BR') : 'N/A'}
Dislikes:     ${typeof dislikes === 'number' ? dislikes.toLocaleString('pt-BR') : dislikes} (via RYD API)
Postado em:   ${publishDate ? new Date(publishDate).toLocaleDateString('pt-BR') : 'N/A'}
`);

  } catch (error) {
    console.error('Erro ao buscar informações:', error.message);
  }
}

// Execução via linha de comando
const url = process.argv[2];
if (!url) {
  console.log('Uso: node index.js <URL_DO_VIDEO>');
} else {
  getYouTubeVideoInfo(url);
}

// Exemplo de uso: node index.js https://www.youtube.com/watch?v=dQw4w9WgXcQ

