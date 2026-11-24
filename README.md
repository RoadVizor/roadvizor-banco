# 🗄️ RoadVizor — Banco de Dados
![MySQL](https://shields.io)

> Sistema de monitoramento de recursos computacionais para servidores de pedágio **Free Flow**.

O **RoadVizor** é um sistema projetado para monitorar a saúde e o desempenho de servidores críticos operando em praças de pedágio Free Flow. Este repositório armazena a estrutura de banco de dados relacional responsável por gerenciar dados de empresas, usuários, infraestrutura física, servidores e seus componentes de hardware.

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Descrição |
| :--- | :--- |
| **MySQL** | Sistema Gerenciador de Banco de Dados Relacional  |
| **SQL** | Linguagem para criação de tabelas, consultas e manipulação de dados |
| **MySQL Workbench** | Ferramenta visual para modelagem ER e administração |

---

## 📐 Modelo de Dados

A estrutura do banco de dados `roadvizor` é organizada nas seguintes entidades relacionais:

```text
roadvizor/
│
├── 🏢 empresa                # Dados das concessionárias
├── 📍 endereco               # Localização física das unidades/servidores
├── 👤 usuario                # Gestores e operadores 
├── 🖥️ servidor               # Servidores implantados nas praças Free Flow
├── 🧩 componente             # Tipos de hardware (CPU, RAM, Disco)
└── 🔗 servidor_componente    # Associação N:M entre servidores e seus componentes
