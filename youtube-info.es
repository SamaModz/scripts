const cheerio = require('cheerio');
const { URL } = require('url');

/**
 * Extrai informações de um vídeo do YouTube usando fetch e cheerio.
 * @param {string} url - URL do vídeo do YouTube.
 * @param {boolean} showDesc - Se deve mostrar apenas a descrição.
 */
async function getYouTubeVideoInfo(url, showDesc) {
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7'
      }
    });

    if (!response.ok) {
      throw new Error(`Erro na requisição: ${response.status} ${response.statusText}`);
    }

    const html = await response.text();
    const $ = cheerio.load(html);

    // Tentar encontrar ytInitialData no script
    const scriptContent = $('script').filter((i, el) => $(el).html().includes('var ytInitialData =')).html();

    let data = null;
    if (scriptContent) {
        try {
            const jsonStr = scriptContent.split('var ytInitialData = ')[1].split(';</script>')[0].trim().replace(/;$/, '');
            data = JSON.parse(jsonStr);
        } catch (e) {}
    }

    // Função para extrair links reais de redirecionamentos do YouTube
    const getCleanUrl = (ytUrl) => {
      if (!ytUrl) return '';
      if (ytUrl.startsWith('/redirect')) {
        try {
          const parsedUrl = new URL('https://www.youtube.com' + ytUrl);
          const q = parsedUrl.searchParams.get('q');
          return q || ('https://www.youtube.com' + ytUrl);
        } catch (e) {
          return 'https://www.youtube.com' + ytUrl;
        }
      }
      return ytUrl.startsWith('/') ? `https://www.youtube.com${ytUrl}` : ytUrl;
    };

    // Função para processar runs de texto/links
    const processRuns = (runs) => {
      if (!Array.isArray(runs)) return '';
      return runs.map(run => {
        const endpoint = run.navigationEndpoint;
        if (endpoint && endpoint.commandMetadata && endpoint.commandMetadata.webCommandMetadata) {
          return getCleanUrl(endpoint.commandMetadata.webCommandMetadata.url);
        }
        return run.text || '';
      }).join('');
    };

    if (showDesc) {
      let fullDescription = '';
      
      if (data) {
          // Tentar Painel de Descrição Estruturada
          const panels = data.engagementPanels || [];
          const structDescPanel = panels.find(p => 
            p.engagementPanelSectionListRenderer && 
            p.engagementPanelSectionListRenderer.targetId === 'engagement-panel-structured-description'
          );

          if (structDescPanel) {
            const content = structDescPanel.engagementPanelSectionListRenderer.content;
            if (content && content.structuredDescriptionContentRenderer) {
                const items = content.structuredDescriptionContentRenderer.items;
                const bodyItem = items.find(i => i.expandableVideoDescriptionBodyRenderer);
                if (bodyItem && bodyItem.expandableVideoDescriptionBodyRenderer.description) {
                  fullDescription = processRuns(bodyItem.expandableVideoDescriptionBodyRenderer.description.runs);
                }
            }
          }

          // Tentar videoSecondaryInfoRenderer
          if (!fullDescription) {
            const findSecondary = (obj) => {
              if (typeof obj !== 'object' || obj === null) return null;
              if (obj.videoSecondaryInfoRenderer) return obj.videoSecondaryInfoRenderer;
              for (const key in obj) {
                const res = findSecondary(obj[key]);
                if (res) return res;
              }
              return null;
            };
            const secondary = findSecondary(data);
            if (secondary && secondary.description) {
              fullDescription = processRuns(secondary.description.runs);
            }
          }
      }

      console.log(fullDescription || $('meta[name="description"]').attr('content') || 'Descrição não encontrada.');
      return;
    }

    // Modo normal
    const title = $('meta[name="title"]').attr('content') || $('title').text().replace(' - YouTube', '');
    const channelName = $('link[itemprop="name"]').attr('content') || $('span[itemprop="author"] link[itemprop="name"]').attr('content');
    const publishDate = $('meta[itemprop="datePublished"]').attr('content');
    const durationISO = $('meta[itemprop="duration"]').attr('content') || 'N/A';

    const formatDuration = (iso) => {
      if (iso === 'N/A') return iso;

      const match = iso.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);

      if (!match) return iso;

      const hours = parseInt(match[1] || 0);
      const minutes = parseInt(match[2] || 0);
      const seconds = parseInt(match[3] || 0);

      const parts = [];

      if (hours > 0) {
        parts.push(`${hours} hora${hours > 1 ? 's' : ''}`);
      }

      if (minutes > 0) {
        parts.push(`${minutes} minuto${minutes > 1 ? 's' : ''}`);
      }

      // opcional: mostrar segundos só se não tiver hora/minuto
      if (seconds > 0 && hours === 0 && minutes === 0) {
        parts.push(`${seconds} segundo${seconds > 1 ? 's' : ''}`);
      }

      return parts.join(' e ');
    };

    let views = 'N/A';
    let likes = 'N/A';
    let dislikes = 'N/A';

    if (data) {
      try {
        const primary = data.contents.twoColumnWatchNextResults.results.results.contents[0].videoPrimaryInfoRenderer;
        views = primary.viewCount.videoViewCountRenderer.viewCount.simpleText.replace(/[^0-9]/g, '');
        const buttons = primary.videoActions.menuRenderer.topLevelButtons;
        const likeBtn = buttons.find(b => b.segmentedLikeDislikeButtonRenderer);
        if (likeBtn) {
          likes = likeBtn.segmentedLikeDislikeButtonRenderer.likeButton.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label.replace(/[^0-9]/g, '');
        }
      } catch (e) {}
    }

    if (views === 'N/A') views = $('meta[itemprop="interactionCount"]').attr('content') || 'N/A';

    try {
      const videoIdMatch = url.match(/(?:v=|\/embed\/|\/1\/|\/v\/|https:\/\/youtu\.be\/)([^"&?\/\s]{11})/);
        if (videoIdMatch) {
          const videoId = videoIdMatch[1];
          const rydResponse = await fetch(`https://returnyoutubedislikeapi.com/votes?videoId=${videoId}`);
          if (rydResponse.ok) {
            const rydData = await rydResponse.json();
            dislikes = rydData.dislikes;
            if (views === 'N/A' || views === '0') views = rydData.viewCount;
            if (likes === 'N/A') likes = rydData.likes;
          }
        }
    } catch (err) {}

    console.log(`Título:       ${title}
Canal:        ${channelName || 'Não encontrado'}
Duração:      ${formatDuration(durationISO)}
Views:        ${parseInt(views || 0).toLocaleString('pt-BR')}
Likes:        ${likes !== 'N/A' ? parseInt(likes).toLocaleString('pt-BR') : 'N/A'}
Dislikes:     ${typeof dislikes === 'number' ? dislikes.toLocaleString('pt-BR') : dislikes} (via RYD API)
Postado em:   ${publishDate ? new Date(publishDate).toLocaleDateString('pt-BR') : 'N/A'}
`);

  } catch (error) {
    console.error('Erro ao buscar informações:', error.message);
  }
}

const args = process.argv.slice(2);
const url = args.find(arg => arg.startsWith('http'));
const showDesc = args.includes('--desc');

if (!url) {
  console.log('Uso: node youtube-info.js <URL_DO_VIDEO> [--desc]');
} else {
  getYouTubeVideoInfo(url, showDesc);
}
