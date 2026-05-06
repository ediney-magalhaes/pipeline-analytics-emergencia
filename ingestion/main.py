import os
import sys
import logging
import subprocess
from flask import Flask, request

# criando servidor web
app = Flask(__name__)

# configurações dos registros de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# definição de regras para a função de ingestão
@app.route("/", methods=["POST"])
def ingestao():
    
    # objeto Flask da requisição
    envelope = request.get_json()
    
    # acessar valor do nome do arquivo no dicionário
    nome_arquivo = envelope.get("nome_arquivo")
    
    # acessar caminho do arquivo no dicionário
    caminho = envelope.get("caminho")

    # verificação do tipo de arquivo para chamar script correspondente
    if "atendimentos" in nome_arquivo:
        script = "ingestao_atendimentos.py"
    elif "internacoes" in nome_arquivo:
        script = "ingestao_internacoes.py"
    elif "movimentacoes" in nome_arquivo:
        script = "ingestao_movimentacoes.py"
    else:
        logging.warning(f"Arquivo não reconhecido: {nome_arquivo}")
        return "Arquivo não reconhecido", 400

    # registro de inicio da ingestão
    logging.info(f"Iniciando ingestão: {script} para {nome_arquivo}")
    
    # rodando script de ingestão
    subprocess.run(["python", script, caminho], check=True)
    return "OK", 200

# verificação do ponto de entrada principal para execução do script
if __name__ == "__main__":
    
    # inciando servidor Flask
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))