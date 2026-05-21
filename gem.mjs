import { GoogleGenAI, Modality } from '@google/genai';
import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
// import cliMarkdown from 'cli-markdown';

// ─────────────────────────────────────────────
const DEBUG = process.argv.includes('--debug');

const t = (label) => {
  if (!DEBUG) return () => {};
  const start = process.hrtime.bigint();
  return () => {
    const end = process.hrtime.bigint();
    const ms = Number(end - start) / 1e6;
    console.log(`⏱️  ${label}: ${ms.toFixed(2)} ms`);
  };
};
// ─────────────────────────────────────────────

const rl = readline.createInterface({ input, output });

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const history = [];
async function main() {
  while (true) {
    const endInput = t('user input');
    const ask = await rl.question('Insert > ');
    endInput();

    if (ask === ':q') {
      rl.close();
      process.exit(0);
    }
    if (ask === ':c') {
      console.clear();
      process.exit(1);
    }

    history.push({
      role: 'user',
      parts: [{ text: ask }],
    });

    const endGemini = t('gemini api');
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: history,
      config: {
        responseMimeType: "text/plain",
        systemInstruction: "Responda apenas em texto simples. Não use negrito (**), itálico, títulos (#) ou listas. Use apenas quebras de linha comuns.",
        responseModalities: [Modality.TEXT],
        
      },
      generationConfig:{
        stopSequencies:["**"]
      }
    });
    endGemini();

    const text = response.text;

    // adiciona resposta do modelo
    history.push({
      role: "system",
      parts: [{
        text: "Sua resposta deve ser curta. Sem textos adicionais em todas elas para economizar tokens e eu poder ter mais tempo de uso com voce tirqndo melhor proveito"
      }],
      role: 'model',
      parts: [{ text }],
    });

    const endRender = t('markdown render');
    const rendered = console.log(`\x1b[1;92m${text}\x1b[0m`)
    endRender();

    console.log(rendered);

    if (DEBUG) {
      console.log(response.usageMetadata);
      console.log(`🧠 Histórico: ${history.length} mensagens`);
    }
  }
}

main();
