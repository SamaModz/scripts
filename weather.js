const axios = require('axios');

// Mapeamento de ícones Nerd Font para códigos de clima do wttr.in
const weatherIcons = {
    '113': ' ', // Sunny
    '116': ' ', // Partly cloudy
    '119': ' ', // Cloudy
    '122': ' ', // Very Cloudy
    '143': ' ', // Fog
    '176': ' ', // Patchy rain possible
    '179': ' ', // Patchy snow possible
    '182': ' ', // Patchy sleet possible
    '185': ' ', // Patchy freezing drizzle possible
    '200': ' ', // Thundery outbreaks possible
    '227': ' ', // Blowing snow
    '230': ' ', // Blizzard
    '248': ' ', // Fog
    '260': ' ', // Freezing fog
    '263': ' ', // Patchy light drizzle
    '266': ' ', // Light drizzle
    '281': ' ', // Freezing drizzle
    '284': ' ', // Heavy freezing drizzle
    '293': ' ', // Patchy light rain
    '296': ' ', // Light rain
    '299': ' ', // Moderate rain at times
    '302': ' ', // Moderate rain
    '305': ' ', // Heavy rain at times
    '308': ' ', // Heavy rain
    '311': ' ', // Light freezing rain
    '314': ' ', // Moderate or Heavy freezing rain
    '317': ' ', // Light sleet
    '320': ' ', // Moderate or heavy sleet
    '323': ' ', // Patchy light snow
    '326': ' ', // Light snow
    '329': ' ', // Patchy moderate snow
    '332': ' ', // Moderate snow
    '335': ' ', // Patchy heavy snow
    '338': ' ', // Heavy snow
    '350': ' ', // Ice pellets
    '353': ' ', // Light rain shower
    '356': ' ', // Moderate or heavy rain shower
    '359': ' ', // Torrential rain shower
    '362': ' ', // Light sleet showers
    '365': ' ', // Moderate or heavy sleet showers
    '368': ' ', // Light snow showers
    '371': ' ', // Moderate or heavy snow showers
    '374': ' ', // Light showers of ice pellets
    '377': ' ', // Moderate or heavy showers of ice pellets
    '386': ' ', // Patchy light rain with thunder
    '389': ' ', // Moderate or heavy rain with thunder
    '392': ' ', // Patchy light snow with thunder
    '395': ' ', // Moderate or heavy snow with thunder
    'default': ' '
};

async function getMyCity() {
    try {
        const { data } = await axios.get('https://ipapi.co/json/');
        return data.city;
    } catch (error) {
        return '';
    }
}

async function getWeather(city = '') {
    const url = `https://wttr.in/${encodeURIComponent(city)}?format=j1&lang=pt`;

    try {
        const { data } = await axios.get(url);

        const current = data.current_condition[0];
        const nearestArea = data.nearest_area[0];
        const weatherDesc = current.lang_pt ? current.lang_pt[0].value : current.weatherDesc[0].value;
        const weatherCode = current.weatherCode;

        const weather = {
            location: `${nearestArea.areaName[0].value}, ${nearestArea.region[0].value} - ${nearestArea.country[0].value}`,
            time: current.localObsDateTime,
            condition: weatherDesc,
            temp: current.temp_C,
            precipitation: `${current.precipMM} mm`,
            humidity: `${current.humidity}%`,
            wind: `${current.windspeedKmph} km/h`,
            hourly: data.weather[0].hourly.map(h => ({
                time: formatTime(h.time),
                temp: h.tempC,
                condCode: h.weatherCode,
                condDesc: h.lang_pt ? h.lang_pt[0].value : h.weatherDesc[0].value
            })),
            forecast: data.weather.map(day => ({
                date: day.date,
                high: day.maxtempC,
                low: day.mintempC,
                condCode: day.hourly[4].weatherCode,
                condDesc: day.hourly[4].lang_pt ? day.hourly[4].lang_pt[0].value : day.hourly[4].weatherDesc[0].value
            }))
        };

        displayWeather(weather, weatherCode);
    } catch (error) {
        console.error('Erro ao buscar o clima:', error.message);
    }
}

function formatTime(timeStr) {
    let hour = parseInt(timeStr) / 100;
    return `${hour.toString().padStart(2, '0')}:00`;
}

function displayWeather(w, currentCode) {
    const icon = weatherIcons[currentCode] || weatherIcons['default'];
        const cols = process.stdout.columns 
    console.log('\n' + '━'.repeat(cols));
    console.log(`    ${w.location}`);
    console.log(`    ${w.time}`);
    console.log('━'.repeat(cols));
    
    console.log(`\n  ${icon} ${w.condition}`);
    console.log(`    ${w.temp}°C`);
    
    console.log(`\n    Precipitação: ${w.precipitation}`);
    console.log(`    Umidade: ${w.humidity}`);
    console.log(`    Vento: ${w.wind}`);
    
    // Previsão Horária (Estilo Google)
    console.log('\n' + '━'.repeat(cols));
    console.log('    PREVISÃO HORÁRIA (HOJE)');
    console.log('━'.repeat(60));
    
    let hourlyLine = '  ';
    w.hourly.forEach(h => {
        const hIcon = weatherIcons[h.condCode] || weatherIcons['default'];
        hourlyLine += `${h.time} ${hIcon}${h.temp}°  `;
    });
    console.log(hourlyLine);

    // Previsão Semanal
    console.log('\n' + '━'.repeat(cols));
    console.log('    PREVISÃO SEMANAL');
    console.log('━'.repeat(60));
    
    w.forecast.forEach(f => {
        const fIcon = weatherIcons[f.condCode] || weatherIcons['default'];
        const dateObj = new Date(f.date + 'T00:00:00');
        const dayName = dateObj.toLocaleDateString('pt-BR', { weekday: 'long' });
        const dateStr = dateObj.toLocaleDateString('pt-BR', { day: 'numeric', month: 'short' });
        
        const dayPadded = (dayName.charAt(0).toUpperCase() + dayName.slice(1)).padEnd(15, ' ');
        const datePadded = dateStr.padEnd(10, ' ');
        
        console.log(`  ${dayPadded} ${datePadded} ${fIcon} ${f.high}° / ${f.low}°  (${f.condDesc})`);
    });
    
    console.log('━'.repeat(cols) + '\n');
}

async function main() {
    const args = process.argv.slice(2);
    let city = '';

    if (args.includes('--my-loc')) {
        console.log('    Detectando sua localização...');
        city = await getMyCity();
    } else {
        city = args.join(' ');
    }

    getWeather(city);
}

main();
