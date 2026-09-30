# 🎙️ SoundKid — Efeitos Sonoros para Contação de Histórias

**SoundKid** é um aplicativo Flutter interativo desenvolvido para transformar a leitura e contação de histórias infantis em uma experiência imersiva e divertida. O aplicativo escuta a narração através do microfone em tempo real e dispara automaticamente efeitos sonoros correspondentes às palavras ditas!

---

## 🚀 Principais Recursos

- 🎤 **Reconhecimento de Voz Contínuo (`speech_to_text`)**: Escuta a narração em tempo real (em português PT-BR) e identifica gatilhos verbais durante a leitura da história.
- 🔊 **Disparo Automático de Efeitos Sonoros (`audioplayers`)**: Executa áudios pré-definidos ou personalizados de forma instantânea assim que uma palavra-chave é detectada.
- ⏱️ **Controle de Cooldown**: Evita acionamentos repetitivos indesejados definindo um tempo de espera (em segundos) configurável para cada som.
- 🎛️ **Modo Mesclar Sons**: Alterne entre sobrepor múltiplos sons simultaneamente ou interromper o som anterior para iniciar um novo.
- ➕ **Cadastro de Sons Personalizados**: Permite adicionar novos efeitos com palavras-chave customizadas e importar arquivos de áudio (`.mp3`, `.wav`, `.m4a`) direto do armazenamento do dispositivo.
- 🎨 **Interface Dark Mode e Moderna**: Design escuro com paleta futurista (Ciano, Rosa e Roxo), feedback visual de escuta ativa e botões de controle rápido (parar todos os sons, pausar individualmente, etc.).

---

## 🛠️ Tecnologias e Pacientes Utilizados

- **[Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)**: Framework multiplataforma.
- **[`speech_to_text`](https://pub.dev/packages/speech_to_text)**: Captura e processamento de fala em tempo real.
- **[`audioplayers`](https://pub.dev/packages/audioplayers)**: Gerenciamento e execução de fontes de áudio (`AssetSource` e `DeviceFileSource`).
- **[`permission_handler`](https://pub.dev/packages/permission_handler)**: Gerenciamento de permissões nativas de microfone.
- **[`file_picker`](https://pub.dev/packages/file_picker)**: Seleção de arquivos de áudio do dispositivo.
- **[`path_provider`](https://pub.dev/packages/path_provider)**: Armazenamento persistente de áudios customizados localmente.

---

## 📁 Estrutura do Projeto

```text
lib/
├── main.dart                  # Ponto de entrada da aplicação
├── models/
│   └── sound_effect.dart      # Modelo de dados (ID, keywords, áudio e cooldown)
├── services/
│   ├── audio_service.dart     # Serviço de controle de áudio, cooldown e mixagem
│   └── speech_service.dart    # Serviço de reconhecimento de fala em PT-BR
└── screens/
    ├── home_screen.dart       # Tela principal (escuta ativa, player e lista de efeitos)
    └── add_sound_screen.dart  # Tela de cadastro e seleção de arquivos personalizados

assets/
├── config/
│   └── sounds_config.json     # Mapeamento inicial de efeitos pré-definidos
├── audio/                     # Arquivos de som integrados (.mp3)
└── images/                    # Recursos visuais (ícones da interface)