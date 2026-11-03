# Event and Space Management Database

Course project for SCC0640 (Databases). A PostgreSQL database for events and the spaces where they happen: event series and editions, activities and sessions, spaces and resources, people with overlapping roles, registrations with limited vacancies, and session change history. Five triggers enforce the business rules.

A Python command-line prototype runs the five project queries and turns natural-language questions into SQL with a local Ollama model (`qwen3:8b`). Generated queries run on a read-only connection.

## How to run

Requirements: PostgreSQL 14+, Python 3.11+, Ollama.

```bash
# 1. Database: copy the "3. DDL COMPLETO" section of Projeto.txt to ddl.sql
createdb -U postgres eventos
psql -U postgres -d eventos -f ddl.sql
psql -U postgres -d eventos -f DML.sql

# 2. Model
ollama pull qwen3:8b

# 3. Prototype (edit Prototipo/config.json first)
cd Prototipo
python -m pip install -r requirements.txt
python main.py
```

## Made by:

- Joao Pedro
- Mateus Saracuza
- Rafael Duarte
- Nicolas
- Pedro Kemp
## References

- [PostgreSQL documentation](https://www.postgresql.org/docs/)
- [Psycopg 3](https://www.psycopg.org/psycopg3/docs/)
- [Ollama Python library](https://github.com/ollama/ollama-python)
- [Qwen3](https://ollama.com/library/qwen3)
- [draw.io](https://www.drawio.com/) and [Mermaid](https://mermaid.js.org/)
