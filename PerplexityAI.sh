#!/usr/bin/env bash
curl 'https://www.perplexity.ai/rest/sse/perplexity_ask' \
  -H 'authority: www.perplexity.ai' \
  -H 'accept: text/event-stream' \
  -H 'accept-language: en-US,en;q=0.9,pt;q=0.8' \
  -H 'content-type: application/json' \
  -H 'cookie: pplx.visitor-id=2f671cd7-fc9d-4ff2-bef0-d3b8327d9685; __podscribe_perplexityai_referrer=https://accounts.google.com/; __podscribe_perplexityai_landing_url=https://www.perplexity.ai/search/crie-um-script-de-shell-simple-rCcbxiVYTueWaIPrizYK6w; _fbp=fb.1.1749603272738.955392444310481372; _gcl_au=1.1.919222145.1749603273; _rdt_uuid=1749603272185.c00fd6a9-3e21-45d4-9f8f-88317a57a0ff; intercom-device-id-l2wyozh0=c7e7e357-5ab1-4301-8226-9301ef563a01; ph_phc_TXdpocbGVeZVm5VJmAsHTMrCofBQu3e0kN8HGMNGTVW_posthog=%7B%22distinct_id%22%3A%220195f3b0-1044-707d-a461-98ca7fef3c2a%22%2C%22%24sesid%22%3A%5B1751383626348%2C%220197c699-4ea3-79b4-ade6-839d67e7d1e3%22%2C1751383625378%5D%7D; pplx.search-mode=search; pplx.session-id=33bca755-312a-4746-9b25-2889871a368e; __cf_bm=xXsHR3_210BzrdHM0EE9S6dgtkN7DZ1vApjwPgOSdJ4-1752261372-1.0.1.1-RlPqRknqBjNk0WT5zQsjifycC1jeg0HYOyj90Xhr6enoZ2nB3bEnz1FRH9dGEHH_NgUliOxSIr4qR2Bw_OaLvbnZBFBlXPmQfIDBDuoqgDI; __cflb=02DiuDyvFMmK5p9jVbVnMNSKYZhUL9aGmn85Cuk3VopoE; comet-custom-color-themes-enabled=true; next-auth.csrf-token=6736a57b83243a180f9ccb434d5510d126333584e52ff7d39a4cbe397bbe9884%7C8a8ab3a1e3a04c356e213d95e9eb284b16672b055fb8ba58df92c4b5e05b8199; next-auth.callback-url=https%3A%2F%2Fwww.perplexity.ai%2Fapi%2Fauth%2Fsignin-callback%3Fredirect%3Dhttps%253A%252F%252Fwww.perplexity.ai; cf_clearance=SSvNrduipMZDOKUJE.HanMdlX9D4esq1K7_S.tMTWDY-1752261647-1.2.1.1-VTodfV6W8QegJRdkP0wiZO.bwXmCvr9BB3iB9gjaaS7PLM6inHgKHKMf63YmEr51krDawxxwFGTvrRanH3VgC2asZ7Y6rMyIYY3UJwxBuP00uF7uS4zYSV.IP3Ef7HFy9Ukr_lX5ufL4JW19H3ai.sfN1CzifXZXpFUzZ6waBbeFr1XI8K4LSXmF_vb.iMOiLLGACJ6eQGuJa1ib_p6gSJLqafjjJP_tVBl0yCupmAU; __Secure-next-auth.session-token=eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..xyX4bqGnylMlsTR6.iElOx5GNWEnOzi3c8sNMVB8yPmPA32WRCgK-su_hxeJOlHDiTmArfUOc_nQlAyUJjchgnsBFLYnrVrAR853wWaMAFvVVP_-HP3UbQhK_deJqk28KplEk05jRg5KhIhx4pwETvZBS4Tg5cOzjHLeqXp3-6plr5rax-do_xZf8Z1S4HAF6gmvOwV105LmcGuEI4CzjRPnnsV-3fNVY7iT1BrATuJV8RAM50P8U-Aff2hnlngiUaJodG3uyoYqfRpzV1yB13dOxHMc-VUMNrFSY_XSpuUZHHiGnFvVEC6a1cCZ_M5O4lFYOPqNfyA_dtHP4qq9M8LShJVxUWH2KTjHkbijjmyCm0nKXCopA1VoZPdAGGWLFe1zrGGpI6t9NgyNXlMdtRGuiRFEwHFqnOngY1AsORAUAaAvrEMnKlsk2kQUET393sr2Py_4.80KEIO72K0TJUHGOH6pQQQ; AWSALB=TR84641/tkQVw/q+v0uECUhm2rWHoLEgU0J2R1RiRo6apZ7cWSX6uucwCggSMxYMs9CnXpwxoY5Zzd4fSyLcxQ+firZUyLXCS/Nl/EqCUzBoSRv96WsTr8quq+qT; AWSALBCORS=TR84641/tkQVw/q+v0uECUhm2rWHoLEgU0J2R1RiRo6apZ7cWSX6uucwCggSMxYMs9CnXpwxoY5Zzd4fSyLcxQ+firZUyLXCS/Nl/EqCUzBoSRv96WsTr8quq+qT; _dd_s=aid=c8d5f66a-1dce-4bed-a398-1f4f59e08539&rum=2&id=dde0df47-934a-4d9e-913e-02676477a8ca&created=1752261374330&expire=1752262560569&logs=0; pplx.metadata={%22qc%22:161%2C%22qcu%22:137%2C%22qcm%22:39%2C%22qcc%22:31%2C%22qcr%22:0%2C%22qcdr%22:0%2C%22qcs%22:0%2C%22qcd%22:0%2C%22hli%22:true%2C%22hcga%22:false%2C%22hcds%22:false%2C%22hso%22:false%2C%22hfo%22:false%2C%22fqa%22:1751830390447%2C%22lqa%22:1752261661518}' \
  -H 'origin: https://www.perplexity.ai' \
  -H 'referer: https://www.perplexity.ai/search/continue-essa-narrativa-sem-te-1qc.DxZVSCaqG1uiLSghqA' \
  -H 'sec-ch-ua: "Chromium";v="137", "Not/A)Brand";v="24"' \
  -H 'sec-ch-ua-arch: ""' \
  -H 'sec-ch-ua-bitness: ""' \
  -H 'sec-ch-ua-full-version: "137.0.7337.0"' \
  -H 'sec-ch-ua-full-version-list: "Chromium";v="137.0.7337.0", "Not/A)Brand";v="24.0.0.0"' \
  -H 'sec-ch-ua-mobile: ?1' \
  -H 'sec-ch-ua-model: "2310FPCA4G"' \
  -H 'sec-ch-ua-platform: "Android"' \
  -H 'sec-ch-ua-platform-version: "15.0.0"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'traceparent: 00-000000000000000097a380c3c87cc251-6d748b5637bf1c06-01' \
  -H 'tracestate: dd=s:1;o:rum' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36' \
  -H 'x-datadog-origin: rum' \
  -H 'x-datadog-parent-id: 7887082049851300870' \
  -H 'x-datadog-sampling-priority: 1' \
  -H 'x-datadog-trace-id: 10926718699301552721' \
  -H 'x-perplexity-request-reason: perplexity-query-state-provider' \
  --data-raw '{"params":{"last_backend_uuid":"6cd4143a-cbeb-43da-bc56-5e244a916733","read_write_token":"d1e3efcd-9713-4aeb-b41c-8941e3612167","attachments":[],"language":"en-US","timezone":"America/Sao_Paulo","search_focus":"internet","sources":["web"],"frontend_uuid":"6274bcf9-802a-4ba5-996e-e173afab32b7","mode":"concise","model_preference":"turbo","is_related_query":false,"is_sponsored":false,"visitor_id":"2f671cd7-fc9d-4ff2-bef0-d3b8327d9685","user_nextauth_id":"2d686923-0f9f-48dd-a6c1-49b06cbced67","prompt_source":"user","query_source":"followup","is_incognito":false,"use_schematized_api":true,"send_back_text_in_streaming_api":false,"supported_block_use_cases":["answer_modes","media_items","knowledge_cards","inline_entity_cards","place_widgets","finance_widgets","sports_widgets","shopping_widgets","jobs_widgets","search_result_widgets","clarification_responses","inline_images","inline_assets","inline_finance_widgets","placeholder_cards","diff_blocks","inline_knowledge_cards"],"client_coordinates":null,"mentions":[],"skip_search_enabled":true,"is_nav_suggestions_disabled":false,"followup_source":"link","version":"2.18"},"query_str":"Ola quanto: 39-29"}' \
  --compressed \
  | grep '^data:' \
  | cut -d' ' -f2- \
  | jq -C