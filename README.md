# Atividade Individual 1: Serverless — Rota Vital

**Instituição:** CESAR School  
**Curso:** Análise e Desenvolvimento de Sistemas (ADS) — 2026.2  
**Disciplina:** Infraestrutura de Software  
**Estudante:** Lucas Mateus  
**Contexto do Sistema:** Projeto Rota Vital (Logística de Transporte de Bolsas de Sangue)  
**Repositório GitHub:** [https://github.com/Lucas-Alves123/atv_individual1](https://github.com/Lucas-Alves123/atv_individual1)  
**Vídeo de Demonstração (até 3 minutos):** [Link do Vídeo no YouTube / Google Drive / Loom](#) *(Adicione o link do seu vídeo aqui)*

---

## 1. Visão Geral e Objetivo

Esta atividade prática tem como objetivo implementar, executar e analisar localmente uma função **serverless** (AWS Lambda simulado via AWS SAM CLI e Docker), disparada tanto por eventos quanto por requisições HTTP, representando o fluxo de emissão de **Guia de Transporte** do sistema **Rota Vital**.

O experimento permite observar na prática os pilares da computação serverless abordados na disciplina:
1. **Ciclo de vida do ambiente de execução:** Fase de inicialização (*Init*), inicialização a frio (*Cold Start*) e reaproveitamento de container (*Warm Start*);
2. **Modelo de execução *Stateless*:** O comportamento de variáveis globais com e sem reaproveitamento de instâncias (`--warm-containers`);
3. **Limites de tempo (*Timeout*):** O impacto do estouro do limite configurado e o tratamento de tarefas assíncronas/longas;
4. **Dimensionamento de custos:** Modelo granular de cobrança da nuvem AWS (por requisição e por GB-segundo).

---

## 2. Caminho Escolhido

- **Caminho Selecionado:** **Caminho A (Recomendado) — AWS SAM CLI Local**.
- **Linguagem / Runtime:** Python 3.12 (pacote Zip).
- **Ambiente de Containers:** Docker Desktop (WSL 2).
- **Ferramental Utilizado:**
  - AWS SAM CLI (`v1.171.0`)
  - Python 3.12.10
  - Docker 28.5.1
  - Git para versionamento

---

## 3. Estrutura do Projeto

```text
├── .aws-sam/                 # Artefatos compilados pelo SAM Build (ignorado no git)
├── events/
│   ├── event.json            # Template base de evento
│   └── pedido.json           # Payload de teste do Rota Vital gerado pelo SAM
├── evidencias/               # Registros e logs textuais das execuções
│   ├── 01_sam_build.txt
│   ├── 02_invocacao_evento.txt
│   ├── 03_http_sem_warm_containers.txt
│   ├── 04_http_com_warm_containers.txt
│   ├── 05_timeout_erro.txt
│   └── 06_timeout_ajustado.txt
├── hello_world/
│   ├── __init__.py
│   ├── app.py                # Handler da função Lambda do Rota Vital
│   └── requirements.txt
├── demo_local_invoke.ps1      # Script utilitário para invocação por evento
├── demo_http_requests.ps1     # Script utilitário para chamadas HTTP
├── demo_timeout_test.ps1      # Script utilitário para teste de Timeout
├── iniciar_servidor.ps1       # Script utilitário para iniciar a API localmente
├── README.md                 # Documentação completa e respostas conceituais
├── samconfig.toml            # Arquivo de configuração do AWS SAM CLI
└── template.yaml             # Infraestrutura como Código (SAM / CloudFormation)
```

---

## 4. Instruções de Execução Passo a Passo (Reprodutibilidade)

### Pré-requisitos
- Docker Desktop rodando.
- AWS SAM CLI instalado (`sam --version`).
- Python 3.12 instalado.

---

### Passo 1: Compilar o Projeto
Gera os artefatos empacotados na pasta `.aws-sam`:
```bash
sam build
```

---

### Passo 2: Invocar a Função por Evento (Passo 3 da Atividade)
Dispara a função diretamente com o evento simulado em `events/pedido.json`:
```bash
sam local invoke -e events/pedido.json
```
*Dica:* Execute o comando duas vezes seguidas para comparar os tempos de *Cold Start* e *Warm Start*. Ou utilize o script fornecido:
```powershell
.\demo_local_invoke.ps1
```

---

### Passo 3: Iniciar a API HTTP Local (Passo 4 da Atividade)

- **Modo padrão (sem warm-containers):**
  ```bash
  sam local start-api
  ```

- **Modo com reaproveitamento de containers (Warm Containers):**
  ```bash
  sam local start-api --warm-containers LAZY
  ```
  *(Ou simplesmente execute `.\iniciar_servidor.ps1`)*

O servidor ficará disponível em: **`http://127.0.0.1:3000/guias`**.

---

### Passo 4: Realizar Chamadas HTTP
Em outro terminal, envie três requisições POST com o corpo JSON:
```bash
curl -X POST http://127.0.0.1:3000/guias \
  -H "Content-Type: application/json" \
  -d '{"requisicaoId":"R-002","hospital":"H-Caruaru"}'
```
*(No PowerShell, você também pode executar `.\demo_http_requests.ps1`)*.

---

### Passo 5: Teste de Limite de Tempo / Timeout (Passo 5 da Atividade)
Envie uma requisição com `"demorar": true`:
```bash
curl -X POST http://127.0.0.1:3000/guias \
  -H "Content-Type: application/json" \
  -d '{"requisicaoId":"R-003","demorar":true}'
```
*(No PowerShell: `.\demo_timeout_test.ps1`)*.
- Com `Timeout: 3` no `template.yaml`: Ocorre erro de timeout (`502 Bad Gateway` / `timed out after 3 seconds`).
- Com `Timeout: 10` no `template.yaml` (após `sam build`): A função conclui os 5 segundos com sucesso e devolve status `201 Created`.

---

## 5. Respostas às Perguntas da Atividade

### Pergunta 1: Por que a primeira invocação demorou mais que a segunda? O que acontece na fase de Init?

**Resposta:**  
A diferença de tempo decorre do fenômeno de **Cold Start** (inicialização a frio), inerente à arquitetura serverless.

Quando a função é invocada pela primeira vez, não existe nenhum container ativo alocado para ela. Portanto, o provedor de computação precisa executar a **Fase de Init**:
1. **Alocação de Infraestrutura:** Criação e inicialização do container ou microVM isolada (via Firecracker na AWS ou container Docker no SAM CLI local);
2. **Inicialização do Runtime:** Carga do interpretador Python 3.12 na memória;
3. **Execução do Código Fora do Handler:** Ocorre a interpretação dos comandos de nível superior do arquivo (importação dos módulos `json` e `time`, e declaração da variável global `contador = 0`).

Somente após a finalização da fase de Init é que a **Fase de Invoke** começa, chamando a função `lambda_handler(event, context)`.

Na **segunda invocação**, ocorre um **Warm Start** (inicialização a quente). Como a imagem e as bibliotecas já estão em cache e o container já foi inicializado, o runtime pula integralmente a fase de Init e vai direto para a execução do handler, resultando em menor latência.

#### Evidência obtida nos testes:
- **1ª Invocação:** Teve overhead de download/montagem do container. No relatório do Lambda: `Duration: 83.24 ms`, `Init Duration: 0.06 ms`, `Billed Duration: 84 ms`.
- **2ª Invocação:** Imagem em cache (`Local image is up-to-date`). No relatório: `Duration: 67.75 ms`, `Init Duration: 0.04 ms`, `Billed Duration: 68 ms` (redução no tempo de resposta).

---

### Pergunta 2: O que o campo `invocacaoNesteAmbiente` mostrou com e sem `--warm-containers`? O que isso diz sobre guardar estado numa variável global da função?

**Resposta:**  

- **Sem `--warm-containers`:**  
  O SAM CLI destrói o container imediatamente após cada requisição HTTP atendida. Quando chega uma nova chamada, um novo container é criado do zero, com a memória limpa. Dessa forma, a variável global `contador = 0` é reinicializada a cada requisição e incrementada para `1`. O campo retornou sempre `1`:
  ```json
  Chamada 1: "invocacaoNesteAmbiente": 1
  Chamada 2: "invocacaoNesteAmbiente": 1
  Chamada 3: "invocacaoNesteAmbiente": 1
  ```

- **Com `--warm-containers LAZY`:**  
  O container é mantido ativo na memória e reutilizado para atender as requisições subsequentes. Assim, o processo Python não é finalizado e o valor da variável global `contador` permanece preservado no escopo do container:
  ```json
  Chamada 1: "invocacaoNesteAmbiente": 1
  Chamada 2: "invocacaoNesteAmbiente": 2
  Chamada 3: "invocacaoNesteAmbiente": 3
  ```

- **O que isso diz sobre guardar estado em variáveis globais:**  
  As funções serverless são concebidas para serem **estritamente *stateless***. O desenvolvedor **nunca deve confiar em variáveis globais para reter estado de negócio** (como sessões, contadores de pedidos ou históricos de dados).  
  Em ambientes de produção na nuvem:
  1. **Concorrência:** Se chegarem 10 requisições simultâneas, o Lambda subirá 10 containers paralelos distintos, cada um com seu próprio contador isolado iniciando em 1.
  2. **Ciclo de vida efêmero:** Containers podem ser destruídos a qualquer instante por ociosidade (scale to zero), manutenção do provedor ou balanceamento de carga.
  
  **Regra arquitetural:** Qualquer estado durável deve ser persistido em serviços externos (bancos relacionais como PostgreSQL/RDS, NoSQL como DynamoDB ou caches distribuídos como Redis/ElastiCache). Variáveis globais devem ser utilizadas exclusivamente para otimizações de performance sem garantia de retenção, como reuso de conexões de banco de dados (*connection pooling*) ou clientes de SDK.

---

### Pergunta 3: O que aconteceu com `demorar = true`? Qual é o tempo máximo de uma execução no Lambda, e o que fazer com um trabalho mais longo?

**Resposta:**  

- **O que aconteceu:**  
  O código possui a seguinte lógica:
  ```python
  if pedido.get("demorar"):
      time.sleep(5)  # dorme 5 segundos
  ```
  Com o arquivo `template.yaml` configurado originalmente com `Timeout: 3` (3 segundos no bloco `Globals.Function`), o Lambda forçou o encerramento da execução aos 3 segundos exatos. O cliente HTTP recebeu status `502 Bad Gateway` e o log registrou:
  ```text
  Function 'HelloWorldFunction' timed out after 3 seconds
  [ERROR] (rapid) Invoke failed error=errResetReceived
  REPORT Duration: 3000.00 ms Billed Duration: 3000 ms Memory Size: 128 MB
  ```
  Após alterarmos o `Timeout` para `10` segundos e executarmos `sam build`, a função conseguiu executar seus 5 segundos de espera sem interrupção (`Duration: 5079.29 ms`), devolvendo com êxito a guia de transporte com status HTTP `201 Created`.

- **Tempo máximo de execução no AWS Lambda:**  
  O limite máximo absoluto de timeout configurável no AWS Lambda é de **15 minutos (900 segundos)**.

- **O que fazer com um trabalho mais longo (> 15 minutos):**  
  Se uma tarefa exceder esse tempo (ex: processamento pesado de arquivos, treinamento de modelos de IA, rotinas de ETL extensas), o modelo Lambda síncrono é inviável. As alternativas recomendadas são:
  1. **AWS Step Functions:** Orquestrar o fluxo de trabalho em etapas menores e encadeadas, dividindo o processo em várias execuções serverless independentes;
  2. **Filas Assíncronas (AWS SQS / EventBridge):** Fragmentar a carga de trabalho em mensagens individuais em lote para que múltiplos consumidores Lambda processem frações menores em paralelo;
  3. **AWS ECS / AWS Fargate:** Executar containers gerenciados em modo serverless, que não possuem o limite de 15 minutos e podem rodar por horas ou dias continuamente;
  4. **AWS Batch:** Serviço focado em computação em lotes sob demanda, alocando recursos de forma otimizada para processamento de alto volume.

---

### Pergunta 4: Com os preços de us-east-1 da aula (US$ 0,20 por milhão de requisições e US$ 0,0000166667 por GB-s), quanto custa um milhão de execuções desta função com 128 MB e 100 ms? Mostrem a conta.

**Resposta:**

#### 1. Parâmetros de Entrada:
- Volume de invocações: $N = 1.000.000$ requisições
- Memória alocada: $128 \text{ MB} = \frac{128}{1024} \text{ GB} = 0,125 \text{ GB}$
- Duração por execução: $100 \text{ ms} = 0,100 \text{ s}$
- Custo por milhão de requisições: $\text{US\$} 0,20$
- Custo por GB-segundo ($\text{GB}\cdot\text{s}$): $\text{US\$} 0,0000166667$

---

#### 2. Custo das Requisições:
$$\text{Custo}_{\text{req}} = 1.000.000 \times \left(\frac{\text{US\$} 0,20}{1.000.000}\right) = \mathbf{\text{US\$} 0,20}$$

---

#### 3. Custo da Computação (Duração em GB-s):
- **Tempo total de execução em segundos:**
  $$\text{Tempo Total} = 1.000.000 \times 0,100 \text{ s} = 100.000 \text{ segundos}$$

- **Consumo total em GB-segundos:**
  $$\text{Consumo}_{\text{GB-s}} = 100.000 \text{ s} \times 0,125 \text{ GB} = 12.500 \text{ GB-s}$$

- **Custo financeiro da duração:**
  $$\text{Custo}_{\text{comp}} = 12.500 \text{ GB-s} \times \text{US\$} 0,0000166667/\text{GB-s} \approx \mathbf{\text{US\$} 0,20833375}$$

---

#### 4. Custo Total Consolidado:
$$\text{Custo Total} = \text{Custo}_{\text{req}} + \text{Custo}_{\text{comp}}$$
$$\text{Custo Total} = \text{US\$} 0,20 + \text{US\$} 0,20833375 = \mathbf{\text{US\$} 0,40833375} \approx \mathbf{\text{US\$} 0,41}$$

> **Observação:** Essa conta considera o custo bruto sob demanda. Vale destacar que a AWS oferece um **Free Tier perpétuo** para o Lambda de 1.000.000 de requisições e 400.000 GB-s mensais, o que tornaria o custo real desta carga igual a **US$ 0,00** dentro da cota gratuita.

---

### Pergunta 5: Em que parte do Rota Vital uma função assim faria sentido, e em qual não faria?

**Resposta:**

#### ✅ Onde FARIA sentido no Rota Vital:
1. **Emissão de Guia de Transporte de Sangue:**  
   Processamento rápido, transacional e disparado sob demanda somente quando um transporte de bolsas é confirmado. Como o volume de transportes é sazonal ao longo do dia, o modelo serverless evita custos ociosos (*pay-as-you-go*).
2. **Disparo de Notificações Críticas (Alertas SMS, WhatsApp, E-mail ou Push):**  
   Envio de alertas assíncronos para motoristas, hospitais de destino e hemocentros notificando a saída ou chegada de uma remessa de emergência.
3. **Validação de Pedidos de Emergência:**  
   Recebimento de uma requisição hospitalar para validar regras de negócio imediatas (compatibilidade sanguínea ABO/Rh, conferência de estoque disponível) antes de encaminhar para a triagem.
4. **Ingestão Periódica de Telemetria de Caixas Térmicas:**  
   Disparo pontual mediante recebimento de dados de sensores IoT de temperatura das caixas de transporte (ex: a cada 2 ou 5 minutos).

#### ❌ Onde NÃO FARIA sentido no Rota Vital:
1. **Rastreamento Contínuo em Tempo Real via WebSockets de Alta Frequência:**  
   Se veículos transmitirem posições de GPS a cada fração de segundo através de conexões persistentes e contínuas, manter funções Lambda abertas para streaming de dados gera um número astronômico de invocações e problemas com conexão persistente, sendo muito mais eficiente utilizar instâncias dedicadas de container (ECS/Fargate) ou corretores MQTT/Kafka.
2. **Otimização Global e Roteirização Complexa de Frota:**  
   Cálculo algorítmico pesado envolvendo roteirização simultânea de dezenas de ambulâncias/vans com dados de trânsito em tempo real, demandando grande consumo de memória persistente, GPU ou tempos superiores a 15 minutos. Essa carga pertence a serviços de processamento em lote (*AWS Batch* ou instâncias EC2 dedicadas).
3. **Armazenamento de Sessão ou Estado Compartilhado:**  
   Tentativas de manter listas de bolsas ou estado de veículos em variáveis globais da função, ignorando a natureza efêmera e *stateless* das funções serverless.

---

## 6. Registro de Evidências

Todas as evidências textuais geradas durante as execuções dos comandos estão organizadas na pasta [`evidencias/`](evidencias):

| Arquivo | Descrição da Evidência |
| :--- | :--- |
| [`01_sam_build.txt`](evidencias/01_sam_build.txt) | Saída da compilação dos artefatos pelo SAM CLI (`sam build`). |
| [`02_invocacao_evento.txt`](evidencias/02_invocacao_evento.txt) | Comparação dos tempos das duas invocações locais por evento (Cold vs. Warm Start). |
| [`03_http_sem_warm_containers.txt`](evidencias/03_http_sem_warm_containers.txt) | 3 chamadas HTTP sem reaproveitamento (`invocacaoNesteAmbiente: 1`). |
| [`04_http_com_warm_containers.txt`](evidencias/04_http_com_warm_containers.txt) | 3 chamadas HTTP com warm containers LAZY (`invocacaoNesteAmbiente: 1, 2, 3`). |
| [`05_timeout_erro.txt`](evidencias/05_timeout_erro.txt) | Disparo com `demorar: true` estourando o limite de 3 segundos (erro 502). |
| [`06_timeout_ajustado.txt`](evidencias/06_timeout_ajustado.txt) | Disparo com `Timeout: 10` concluindo os 5 segundos com sucesso (HTTP 201). |

---

## 7. Declaração de Uso de Inteligência Artificial (PO-CESAR-021)

Em conformidade com a política institucional PO-CESAR-021 do CESAR School, declara-se a utilização de ferramentas de Inteligência Artificial generativa no desenvolvimento desta atividade:

- **Ferramenta Utilizada:** Antigravity (com modelo Google Gemini).
- **Finalidade:**  
  - Diagnóstico e configuração do ambiente local com AWS SAM CLI e Docker Desktop no Windows;
  - Criação de scripts PowerShell utilitários para automação das chamadas de teste e gravação do vídeo;
  - Estruturação dos testes de ciclo de vida (Cold Start, Warm Containers e Timeout);
  - Revisão teórica da modelagem matemática de custos e elaboração da documentação técnica no `README.md`.
- **Como Foi Validado:**  
  - Todos os comandos, invocações e requisições HTTP foram executados no terminal local e validados contra os logs reais gerados pelo runtime do Docker/SAM CLI;
  - As saídas das requisições foram checadas individualmente (status HTTP 201 e 502, corpo da resposta e tempos de duração);
  - As fórmulas de faturamento da AWS foram recalculadas manualmente com base na documentação oficial de precificação do AWS Lambda na região `us-east-1`.
