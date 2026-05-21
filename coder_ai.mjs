import { GoogleGenAI } from '@google/genai';
import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';
import cliMarkdown from 'cli-markdown';
import fs from 'node:fs/promises';
import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import path from 'node:path';
import { info } from 'node:console';

const execAsync = promisify(exec);

// ─────────────────────────────────────────────
const DEBUG = process.argv.includes('--debug');
const targetFile = process.argv[2];

if (!targetFile) {
  console.error('❌ Erro: Você deve passar o caminho de um arquivo como argumento.');
  console.log('Uso: node ai_coder.js <arquivo> [--debug]');
  process.exit(1);
}

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

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error('❌ Erro: A variável de ambiente GEMINI_API_KEY não está definida.');
  process.exit(1);
}

const ai = new GoogleGenAI({
  apiKey: apiKey,
});

// 🧠 Histórico em memória
const history = [];

/**
 * Executa um comando e retorna o resultado formatado
 */
async function runCommand(command) {
  console.log(`\n🚀 Executando: ${command}`);
  try {
    const { stdout, stderr } = await execAsync(command);
    return {
      success: true,
      stdout: stdout || '(vazio)',
      stderr: stderr || '(vazio)'
    };
  } catch (error) {
    return {
      success: false,
      stdout: error.stdout || '(vazio)',
      stderr: error.stderr || '(erro crítico)',
      error: error.message
    };
  }
}

async function main() {
  console.log(`\n📂 Arquivo alvo: ${path.resolve(targetFile)}`);

  // Prompt inicial para dar contexto à IA
  let systemPrompt = `
Você é um engenheiro de software especialista. 
Seu objetivo é criar ou melhorar o script no arquivo: ${targetFile}.
Você tem acesso às seguintes ferramentas via 
comandos de texto na sua resposta:
1. Para LER o arquivo: 
responda apenas com "READ_FILE"
2. Para ESCREVER no arquivo: 
responda com "WRITE_FILE" seguido do código entre crases triplas (\`\`\`)
3. Para EXECUTAR o arquivo: 
responda apenas com "EXECUTE"
4. Para FINALIZAR quando o script estiver perfeito: 
responda apenas com "DONE"

Sempre que você ler, escrever ou executar,
eu te darei o feedback do resultado 
(conteúdo do arquivo ou stdout/stderr).
Analise os erros e itere até que o script
esteja "muito bom".`;

  if(process.argv.includes(["--minimal","-m"])){
return systemPrompt = `${systemPrompt}. Sua resposta deve ser bem Minima, com alteracoes diretas. Sera limitado a apenas 5 alteracoes. Voce nao é obrigado a usar todas`;
  }
  history.push({
    role: 'user',
    parts: [{ text: systemPrompt }],
  });

  let iteration = 1;

  while (true) {
    console.log(`\n🔄 Iteração ${iteration}...`);

    const endGemini = t('gemini api');
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: history,
    });
    endGemini();

    const text = response.text;

    // Adiciona resposta do modelo ao histórico
    history.push({
      role: 'model',
      parts: [{ text }],
    });

    const rendered = cliMarkdown(text);
    console.log(rendered);

    let nextInput = "";

    if (text.includes("DONE")) {
      console.log("\n✅ IA finalizou o trabalho!");
      rl.close();
      process.exit(0);
    } else if (text.includes("READ_FILE")) {
      try {
        const content = await fs.readFile(targetFile, 'utf-8');
        nextInput = `Conteúdo atual de ${targetFile}:\n\`\`\`\n${content}\n\`\`\``;
      } catch (err) {
        nextInput = `Erro ao ler arquivo: ${err.message}. Talvez ele ainda não exista? Você pode criá-lo com WRITE_FILE.`;
      }
    } else if (text.includes("WRITE_FILE")) {
      const codeMatch = text.match(/```(?:[a-z]+)?\n([\s\S]*?)```/);
      if (codeMatch) {
        const code = codeMatch[1];
        await fs.writeFile(targetFile, code, 'utf-8');
        nextInput = `Arquivo ${targetFile} atualizado com sucesso.`;
      } else {
        nextInput = "Erro: Você disse WRITE_FILE mas não forneceu o código entre crases triplas.";
      }
    } else if (text.includes("EXECUTE")) {
      const result = await runCommand(`node ${targetFile}`);
      nextInput = `Resultado da execução:\nSTDOUT:\n${result.stdout}\nSTDERR:\n${result.stderr}`;
      if (!result.success) {
        nextInput += `\nERRO DE EXECUÇÃO: ${result.error}`;
      }
    } else {
      // Se a IA apenas falou algo sem comando, pedimos para ela agir
      console.log("\n💬 IA enviou uma mensagem. Aguardando comando ou input do usuário...");
      nextInput = await rl.question('Sua resposta para a IA (ou pressione Enter para pedir ação): ');
      if (!nextInput) nextInput = "Por favor, continue com a tarefa usando READ_FILE, WRITE_FILE, EXECUTE ou finalize com DONE.";
    }

    history.push({
      role: 'user',
      parts: [{ text: nextInput }],
    });

    iteration++;
  }
}

main().catch(err => {
  console.error("💥 Erro fatal:", err);
  process.exit(1);
});
