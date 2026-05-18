# 🗄️ MSSQL-Scripts

Repositório de scripts T-SQL para administração e monitoramento de ambientes **SQL Server 2016+**. Organizados por categoria.

---

## 📁 Estrutura do Repositório

```
MSSQL-Scripts/
├── alwayson/     # Análise e monitoramento dos always on disponíveis
├── backups/      # Verificação e histórico de backups
├── blocking/     # Análise de bloqueios e sessões em espera
├── indexes/      # Análise e manutenção de índices
└── tempdb/       # Monitoramento de espaço e uso do TempDB
```

---

## ⚙️ Pré-requisitos

- **SQL Server 2016 Enterprise** ou superior
- [`sp_WhoIsActive`](http://whoisactive.com/downloads/) instalada no database `master` — necessária para os scripts da pasta `blocking`
- Permissão de `VIEW SERVER STATE` para scripts de monitoramento

---

## 🚀 Como Usar

### Clonando o repositório

```bash
git clone https://github.com/NlaCode/MSSQL-Scripts.git
```

### Executando os scripts

1. Abra o **SSMS** e conecte-se à instância desejada
2. Abra o script via **File > Open > File** ou pelo **Solution Explorer**
3. Ajuste os parâmetros indicados no topo de cada script (quando necessário)
4. Execute com **F5** ou clique em **Execute**

---

## 🤝 Contribuindo

A branch `main` está protegida. Todo contribuidor deve seguir o fluxo abaixo:

```bash
# 1. Crie uma branch a partir da main
git checkout -b feature/nome-do-script

# 2. Adicione ou edite os scripts na pasta correspondente

# 3. Commit
git add .
git commit -m "Descrição clara do que foi feito"

# 4. Push da branch
git push origin feature/nome-do-script

# 5. Abra um Pull Request no GitHub para revisão e merge
```

> ⚠️ Push direto na `main` está bloqueado. Toda alteração deve passar por **Pull Request**.

---

## 📐 Padrões e Convenções

- Sempre inclua um **cabeçalho** no topo do script com descrição e objetivo
- Parâmetros ajustáveis devem ficar no **início do script**, comentados
- Use `SET NOCOUNT ON` em scripts com tabelas temporárias
- Prefira `EXISTS (SELECT 1 ...)` em vez de `EXISTS (SELECT * ...)`
- Evite `SELECT *` — liste sempre as colunas explicitamente
- Nomeie os arquivos em inglês, com palavras separadas por espaço e iniciais maiúsculas

---

## 📌 Observações

- Scripts desenvolvidos e testados em **SQL Server 2016 Enterprise**
- Algumas funcionalidades podem não estar disponíveis em versões ou edições anteriores
- Scripts de bloqueio requerem `sp_WhoIsActive` instalada em `master` e permissão `VIEW SERVER STATE`

---

## 📄 Licença

Uso interno. Todos os direitos reservados à **NlaCode**.
