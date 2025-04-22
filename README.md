# Diário Pessoal

Um app Flutter para registro de anotações pessoais com autenticação Firebase, Firestore.  
Este projeto utiliza um ambiente `.env` para proteger chaves sensíveis e está pronto para rodar em dispositivos Android.

---

## Requisitos

Antes de rodar o projeto, certifique-se de ter os seguintes itens instalados:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio ou VS Code com suporte Flutter](https://docs.flutter.dev/tools)
- Dispositivo Android (real ou emulador)
- Conta no [Firebase](https://console.firebase.google.com)

---

## Configuração do Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com).
2. Ative os seguintes serviços:
   - **Authentication (Email/Senha)**
   - **Firestore Database**
3. No menu de configurações do projeto:
   - Vá até **Configurações do Projeto > Suas apps**
   - Registre seu app Android com o **Package name** do projeto.
   - Baixe o arquivo `google-services.json` e adicione na pasta:

     ```
     android/app/google-services.json
     ```

---

## Variáveis de ambiente

1. Na raiz do projeto, crie um arquivo chamado `.env` com as seguintes chaves:

API_KEY=SUA_API_KEY

APP_ID=SEU_APP_ID

MESSAGING_SENDER_ID=SEU_SENDER_ID

PROJECT_ID=SEU_PROJECT_ID

STORAGE_BUCKET=SEU_BUCKET

Você encontra essas informações no painel do Firebase, em Configurações do projeto.

## Rodando o Projeto no Celular Android
Conecte seu celular (com modo desenvolvedor ativado) ou inicie um emulador.

No terminal, na raiz do projeto, instale as dependências e execute o app com os comandos:

flutter pub get
flutter run
