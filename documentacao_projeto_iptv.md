# DOCUMENTAÇÃO DE ESPECIFICAÇÃO TÉCNICA: IPTV PLAYER CORE
**Destinatário:** Equipe Antigravity  
**Status:** Proposta Inicial / Alinhamento de Escopo  
**Formato do Arquivo:** Markdown (.md)  

---

## 1. Visão Geral do Projeto

O objetivo deste projeto é o desenvolvimento de um aplicativo reprodutor de mídia focado no protocolo IPTV (Internet Protocol Television). O aplicativo atuará estritamente como um **client-side media player neutro**, o que significa que ele não fornecerá, hospedará ou comercializará qualquer tipo de conteúdo de streaming ou listas de canais. Os usuários finais serão responsáveis por fornecer suas próprias URLs de playlists (nos formatos M3U/M3U8) ou credenciais de serviços compatíveis (como Xtream Codes).

### Objetivos Principais:
* **Alta Performance:** Renderização fluida de interfaces de canais e tempo mínimo de buffer de vídeo.
* **Neutralidade Legal:** Cumprimento rigoroso das diretrizes da Google Play Store e Apple App Store para evitar banimentos.
* **Experiência de Usuário (UX) Moderna:** Navegação intuitiva inspirada em plataformas de streaming líderes de mercado (Netflix, IPTV Smarters, Tivimate), otimizada tanto para dispositivos móveis quanto para Android TV/TV Boxes.

---

## 2. Arquitetura do Sistema e Stack Tecnológica

Para garantir portabilidade, facilidade de manutenção e máxima performance na execução de streams ao vivo, propõe-se a seguinte estrutura:

### 2.1. Frontend / Aplicação Core
* **Abordagem Multiplataforma:** **Flutter (Dart)** ou **React Native (TypeScript)**.
    * *Recomendação:* **Flutter** devido ao controle granular sobre a camada de renderização de UI (importante para grades extensas de canais) e excelente ecossistema de pacotes de vídeo nativos.
* **Video Engine (Core de Reprodução):**
    * **Android / Android TV:** Integração com **ExoPlayer** (via AndroidX Media3). É o padrão de mercado para suporte nativo a protocolos HLS (`.m3u8`), MPEG-DASH e streams de transporte (`.ts`).
    * **iOS / Apple TV:** Integração com **AVPlayer** nativo.

### 2.2. Armazenamento Local (Local Database)
Como as listas M3U podem conter de 5.000 a mais de 100.000 linhas, o aplicativo não pode processar o arquivo de texto em memória a cada inicialização.
* **Tecnologia:** **SQLite** via abstração (como Room no Android nativo ou Drift/Floor no Flutter).
* **Objetivo:** Indexar canais, categorias, logotipos, EPG (Guia de Programação) e históricos de reprodução para consultas em milissegundos.

---

## 3. Arquitetura de Módulos (Componentes Core)

O aplicativo será dividido em 4 módulos principais auto-contidos:

```
[ Módulo de Interface (UI) ] <---> [ Módulo de Gerenciamento de Estado ]
                                                  |
                                                  v
[ Video Engine (Player) ]    <---> [ Banco de Dados Local (SQLite) ]
                                                  ^
                                                  |
                                     [ Módulo Core Parser & EPG ]
```

### 3.1. Módulo 1: Parser M3U/M3U8 e Sincronização
Responsável por realizar a requisição HTTP GET na URL fornecida pelo usuário, baixar a lista de reprodução textualmente e convertê-la em registros estruturados no banco de dados.

* **Lógica de Parsing (Regex Base):**
    O parser deve ler o arquivo linha por linha identificando as tags padrão do formato M3U estendido:
    * `#EXTM3U`: Cabeçalho do arquivo.
    * `#EXTINF:<duração> tvg-id="<id_epg>" tvg-name="<nome>" tvg-logo="<url_logo>" group-title="<categoria>",<Nome do Canal>`
    * A linha subsequente representa a `URL_STREAM`.

### 3.2. Módulo 2: Engine de EPG (Electronic Program Guide)
Módulo secundário focado em baixar arquivos XMLTV (geralmente compactados em `.gz` ou `.xml`).
* Mapeia o atributo `tvg-id` do canal com o id do programa no XML.
* Exibe na interface o que está passando no momento (Current Program) e a barra de progresso do tempo decorrido.

### 3.3. Módulo 3: Local Storage Manager (Modelagem)
Esquema simplificado de tabelas necessárias no banco local:
* `Playlists`: id, nome_customizado, url_origem, data_atualizacao.
* `Categories`: id, playlist_id, nome_categoria (ex: "Filmes", "Esportes").
* `Streams`: id, category_id, playlist_id, nome, url_video, url_logo, tvg_id, is_favorite (boolean).
* `PlaybackHistory`: id, stream_id, data_acesso, ultima_posicao (para VOD).

### 3.4. Módulo 4: Video Player Wrapper
Camada abstrata que faz a ponte entre a UI e o player nativo (ExoPlayer/AVPlayer).
* **Recursos Obrigatórios:**
    * Tratamento de troca dinâmica de aspecto de tela (16:9, 4:3, esticado, original).
    * Suporte a seleção de faixas de áudio alternativas (Dual Áudio).
    * Suporte a legendas embutidas (Closed Captions) ou externas (SRT/VTT).
    * Reconexão automática inteligente em caso de perda momentânea de pacotes de rede (Network Dropping).

---

## 4. Requisitos do Projeto

### 4.1. Requisitos Funcionais (RF)
* **RF-001:** O usuário deve ser capaz de adicionar múltiplas listas IPTV via URL remota.
* **RF-002:** O sistema deve categorizar automaticamente os canais conforme a tag `group-title` da lista.
* **RF-003:** O usuário deve conseguir marcar canais, filmes ou séries como "Favoritos".
* **RF-004:** O aplicativo deve possuir uma barra de busca global para localizar canais instantaneamente.
* **RF-005:** O player de vídeo deve possuir controles overlay (Play/Pause, Bloqueio de Tela, Seleção de Áudio/Legenda, Ajuste de Brilho e Volume por gestos na tela).
* **RF-006:** Suporte a modo PiP (Picture-in-Picture) em dispositivos compatíveis.

### 4.2. Requisitos Não-Funcionais (RNF)
* **RNF-001 (Desempenho):** O processo de parsing de uma lista de 20.000 canais não deve travar a UI principal (deve rodar em uma Thread separada / Background Worker / Isolate).
* **RNF-002 (Usabilidade):** O tempo de carregamento (Zapping) entre um canal e outro deve ser inferior a 2 segundos em conexões estáveis broadband.
* **RNF-003 (Design):** Interface escura (Dark Mode por padrão), focada em consumo de mídia noturno.
* **RNF-004 (Portabilidade):** Código estruturado de forma a facilitar o build para Android TV e Amazon Fire Stick (navegação baseada em D-Pad/Controle Remoto).

---

## 5. Diretrizes de Segurança e Publicação (Compliance)

Para mitigar riscos de rejeição ou banimento nas lojas de aplicativos, o desenvolvimento seguirá as seguintes regras:
1.  **Zero-Content-Preloaded:** O binário final do app não conterá nenhuma URL, link ou string que aponte para conteúdos piratas ou canais de TV aberta/fechada.
2.  **Disclaimer de Entrada:** Na primeira inicialização, o app exibirá termos de uso claros afirmando que o app é apenas um reprodutor e não se responsabiliza pelas listas adicionadas.
3.  **User-Agent customizável:** Implementar a opção técnica de alterar o HTTP User-Agent nas requisições de vídeo, pois alguns provedores de IPTV bloqueiam players genéricos.

---

## 6. Próximos Passos Sugeridos para o Kick-off

Para iniciarmos o desenvolvimento em conjunto com a **Antigravity**, propomos a seguinte divisão de tarefas para a Sprint 1 (Definição do MVP):

1.  **Design & Wireframing:** Desenhar o fluxo da tela de adição de lista e a arquitetura da tela do Player de Vídeo.
2.  **PoC (Prova de Conceito) do Parser:** Escrever o algoritmo isolado em Dart/TypeScript para processar uma lista mockada de grande porte e medir o consumo de CPU/Memória.
3.  **Configuração do Repositório:** Setup estrutural do projeto Git com linters estritos para garantir a padronização do código desde o dia zero.
