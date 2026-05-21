Pra usar o cliente HTTP que te passei é igual ao Axios mesmo. Vou te mostrar os casos mais comuns:

1. *Uso básico - GET*
import api from './httpClient.js' // ou require('./httpClient.js')

async function getUser() {
  try {
    const res = await api.get('/users/octocat')
    console.log(res.data)        // dados da resposta
    console.log(res.status)      // 200
    console.log(res.headers)     // headers da resposta
  } catch (err) {
    console.log('Deu ruim:', err.message)
    console.log('Status:', err.response?.status)
  }
}

getUser()
2. *POST com body*
async function createUser() {
  const res = await api.post('/users', {
    name: 'João',
    email: 'joao@email.com'
  })
  console.log(res.data) // resposta da API
}

createUser()
3. *Passando headers e params*
const res = await api.get('/search', {
  headers: { 'X-API-Key': '123' },
  timeout: 5000
})
4. *Usando interceptors*

Já deixei configurado. Pra adicionar um token em todas as requests:
api.interceptors.request.push(config => {
  config.headers.Authorization = 'Bearer seu_token_aqui'
  return config
})

// Agora todas as requests vão ter o Authorization
api.get('/protected-route')
5. *Tratando erro igual Axios*

O erro vem com `response` dentro, igual Axios faz:
try {
  await api.get('/nao-existe')
} catch (err) {
  if (err.response) {
    console.log(err.response.status)   // 404
    console.log(err.response.data)     // body do erro
  } else {
    console.log('Erro de rede:', err.message)
  }
}
6. *Criando instância com baseURL*
const github = api.create({ baseURL: 'https://api.github.com' })
const viacep = api.create({ baseURL: 'https://viacep.com.br/ws' })

await github.get('/users/octocat')     // https://api.github.com/users/octocat
await viacep.get('/01000/json')     // https://viacep.com.br/ws/01000/json
7. *PUT, DELETE, PATCH*
await api.put('/users/1', { name: 'Novo Nome' })
await api.delete('/users/1')
await api.patch('/users/1', { active: false })
8. *Com query params*

Como não tem `params` nativo, faz assim:
const userId = 123
await api.get(`/users/${userId}?page=1&limit=10`)
Ou cria um helper rápido:
const buildQuery = obj => '?' + new URLSearchParams(obj).toString()
await api.get('/users' + buildQuery({ page: 1, limit: 10 }))
*Dica*: Se você usar Node <18, troca `fetch` por `node-fetch` no topo do arquivo:
import fetch from 'node-fetch'


Boa, pra adicionar `FormData` no cliente são só 3 alterações:

As 3 linhas pra adicionar

*1. Dentro do `request`, antes do `fetch`, troca o `body`:*
const isFormData = finalConfig.data instanceof FormData
*2. Ainda no `request`, no `fetch`, troca o `body` e `headers`:*
body: finalConfig.data,
headers: isFormData 
  ? { ...finalConfig.headers, 'Content-Type': undefined } 
  : finalConfig.headers
*3. No `post`/`put`/`patch`, deixa o usuário passar FormData direto:*
post(url, data, config = {}) {
  return this.request({ ...config, method: 'POST', url, data })
}
Essa terceira já tá no código. Só precisa das 2 primeiras.

Código completo com FormData

Troca só o método `request` por esse:
async request(config) {
  const start = Date.now()
  const url = this.baseURL + (config.url || '')
  const method = (config.method || 'GET').toUpperCase()
  
  let finalConfig = { ...this.defaults, ...config }
  
  // Executa interceptors de request
  for (const interceptor of this.interceptors.request) {
    finalConfig = await interceptor(finalConfig)
  }

  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), finalConfig.timeout)

  // 1. Detecta se é FormData
  const isFormData = finalConfig.data instanceof FormData

  try {
    const response = await fetch(url, {
      method,
      // 2. Se for FormData, não seta Content-Type, o browser/node seta sozinho com boundary
      headers: isFormData 
        ? { ...finalConfig.headers, 'Content-Type': undefined } 
        : finalConfig.headers,
      body: finalConfig.data,
      signal: controller.signal
    })
    
    clearTimeout(timeoutId)
    const time = Date.now() - start
    
    let data
    const contentType = response.headers.get('content-type')
    if (contentType?.includes('application/json')) {
      data = await response.json()
    } else {
      data = await response.text()
    }

    const result = {
      data,
      status: response.status,
      statusText: response.statusText,
      headers: Object.fromEntries(response.headers.entries()),
      config: finalConfig,
      url
    }

    let finalResult = result
    for (const interceptor of this.interceptors.response) {
      finalResult = await interceptor(finalResult)
    }

    log.req(method, url, response.status, time)
    
    if (!response.ok) {
      throw { response: finalResult, message: `Request failed with status ${response.status}` }
    }
    
    return finalResult
    
  } catch (error) {
    clearTimeout(timeoutId)
    const time = Date.now() - start
    log.error(`Request failed: ${method} ${url} - ${error.message}`)
    throw error
  }
}
Como usar FormData
import fs from 'fs'
import FormData from 'form-data' // npm i form-data se for Node <18

const form = new FormData()
form.append('file', fs.createReadStream('./foto.jpg'))
form.append('name', 'Minha foto')

await api.post('/upload', form) // Pronto, já envia com multipart/form-data
*Por que essas 3 linhas*: 
1. Detecta se o body é FormData
2. Remove `Content-Type: application/json` porque o FormData precisa de `multipart/form-data` com boundary
3. O resto já funciona porque `fetch` aceita FormData direto no body

Testa aí. Se der erro de `FormData is not defined` no Node, instala: `npm i form-data`