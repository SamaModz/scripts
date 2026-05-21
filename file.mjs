import axios from 'axios';
import * as cheerio from 'cheerio';



























// COLORS
const cls = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  white: "\x1b[37m",
  underline: "\x1b[4m",
}

async function buscarTop5Poco(modelo) {
  const query = encodeURIComponent(modelo);
  // Ordenando por menor preço (price_asc)
  const url = `https://buscape.com.br/search?q=${query}&sort=price_asc`;

  console.log(`🔎 Mapeando Top 5 menores preços para: ${modelo}...\n`);

  try {
    const { data } = await axios.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
      }
    });

    const $ = cheerio.load(data);
    const resultados = [];

    // Seleciona todos os cards de produto
    $('[data-testid="product-card"]').each((i, element) => {
      if (i < 5) { // Limita aos 5 primeiros
        const nome = $(element).find('[data-testid="product-card::name"]').text().trim();
        const preco = $(element).find('[data-testid="product-card::price"]').text().trim();
        const link = "https://buscape.com.br" + $(element).find('a').attr('href');

        if (nome && preco) {
          resultados.push({ i: i + 1, nome, preco, link });
        }
      }
    });

    if (resultados.length > 0) {
      const cols = process.stdout.columns || 80;
      console.log(`🏆 OS 5 MENORES PREÇOS ENCONTRADOS:`);
      console.log("—".repeat(cols));
      resultados.forEach(res => {

        // with COLORS
        const precoStr = `${cls.green}${res.preco}${cls.reset}`;
        const nomeStr = `${cls.cyan}Produto:${cls.reset} ${res.nome}`;
        const linkStr = `${cls.yellow}Link:${cls.reset} ${res.link}`;

        console.log(`${"".repeat(cols)}\n${precoStr}\n${nomeStr}\n${linkStr}\n${"".repeat(cols)}`);
      });
    } else {
      console.log('❌ Nenhum resultado encontrado. Tente um termo mais genérico.');
    }
  } catch (error) {
    console.error('Erro na requisição:', error.message);
  }
}

// Executa a busca
// Exemplo de uso: node file.mjs --product "iPhone 14"
const argument = process.argv.find(arg => arg.startsWith('--product='));
if (argument) {
  const modelo = argument.split('=')[1];
  buscarTop5Poco(modelo);
}

