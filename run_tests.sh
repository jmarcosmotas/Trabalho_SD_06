#!/usr/bin/env bash

# Executar um cenário de teste
executar_teste() {
    local nome="$1"
    local perfil="$2"
    local usuarios="$3"

    for repeticao in $(seq -w 1 10); do
        echo "[INÍCIO] ${nome} - Repetição ${repeticao}/10" >> results/execution_logs.txt

        # Executar o Locust em segundo plano
        locust -f locustfile.py "$perfil" \
            --headless -u "$usuarios" -r 5 -t 6m \
            --host http://localhost:8081 \
            --csv "results/${nome}_rep${repeticao}" \
            --csv-full-history &

        locust_pid=$!

        # Coletar CPU enquanto o Locust estiver em execução
        while kill -0 "$locust_pid" 2>/dev/null; do
            docker stats vets-service customers-service \
                --no-stream \
                --format '{{.Name}},{{.CPUPerc}}' 2>/dev/null |
            while IFS=, read -r container cpu; do
                [[ -n "$container" && -n "$cpu" ]] || continue

                echo "${nome},${repeticao},${container},${cpu//%/}" \
                    >> results/cpu_metrics.csv
            done

            sleep 4
        done

        # Aguardar o Locust e capturar o código de saída
        wait "$locust_pid"
        codigo=$?

        echo "[FIM] ${nome} - Repetição ${repeticao}/10 (código: ${codigo})" \
            >> results/execution_logs.txt

        sleep 5
    done
}

# Criar a pasta de resultados
mkdir -p results

# Cabeçalho do CSV de CPU
echo "cenario,repeticao,container,cpu_percent" > results/cpu_metrics.csv

# Executar os seis cenários
executar_teste "leitura_leve" PerfilLeitura 30
executar_teste "leitura_moderada" PerfilLeitura 80
executar_teste "leitura_elevada" PerfilLeitura 150

executar_teste "escrita_leve" PerfilEscrita 30
executar_teste "escrita_moderada" PerfilEscrita 80
executar_teste "escrita_elevada" PerfilEscrita 150












