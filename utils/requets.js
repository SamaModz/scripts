const c = {
  reset: '\x1b[0m',
  red: '\x1b[1;91m',
  green: '\x1b[1;92m',
  yellow: '\x1b[1;93m',
  blue: '\x1b[1;94m',
  pink: '\x1b[1;95m',
  white: '\x1b[1;96m'
}

const log = {
  success: (msg) => console.log(`${c.white}[${c.green}!${c.white}]${c.reset} ${msg}`),
  error: (msg) => console.log(`${c.white}[${c.red}!${c.white}]${c.reset} ${msg}`),
  req: (method, url, status, time) => {
    const color = status >= 500 ? c.red : status >= 400 ? c.yellow : status >= 300 ? c.blue : c.green
    console.log(`${c.white}[${color}!${c.white}]${c.reset} ${c.white}${method.padEnd(6)}${c.reset} ${url} ${color}${status}${c.reset} ${c.pink}${time}ms${c.reset}`)
  }
}

class HttpClient {
  constructor(baseURL = '') {
    this.baseURL = baseURL
    this.defaults = {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      timeout: 10000
    }
    this.interceptors = {
      request: [],
      response: []
    }
  }

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

  get(url, config = {}) {
    return this.request({ ...config, method: 'GET', url })
  }

  post(url, data, config = {}) {
    return this.request({ ...config, method: 'POST', url, data })
  }

  put(url, data, config = {}) {
    return this.request({ ...config, method: 'PUT', url, data })
  }

  delete(url, config = {}) {
    return this.request({ ...config, method: 'DELETE', url })
  }

  patch(url, data, config = {}) {
    return this.request({ ...config, method: 'PATCH', url, data })
  }

  create(config) {
    const instance = new HttpClient(config.baseURL || this.baseURL)
    instance.defaults = { ...this.defaults, ...config }
    return instance
  }
}

// Uso igual Axios
const api = new HttpClient('https://api.github.com')

api.get('/users/octocat')
  .then(res => console.log(res.data))
  .catch(err => console.log('Erro:', err.message))

// Com interceptors
api.interceptors.request.push(config => {
  config.headers.Authorization = 'Bearer token123'
  return config
})

api.interceptors.response.push(response => {
  if (response.status === 401) {
    log.error('Não autorizado')
  }
  return response
})

ex:wq
port default api
