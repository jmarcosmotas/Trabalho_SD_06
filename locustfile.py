import uuid
import gevent

from locust import HttpUser, between, task, events


CUSTOMERS_URL = "http://localhost:8081"
VETS_URL = "http://localhost:8083"

WARMUP_SECONDS = 60

@events.test_start.add_listener
def reset_stats_after_warmup(environment, **kwargs):
    gevent.spawn_later(WARMUP_SECONDS, environment.stats.reset_all)

class PetClinicUser(HttpUser):

    host = CUSTOMERS_URL
    wait_time = between(1, 2)

    def listar_owners(self):
        self.client.get("/owners", name="GET /owners")

    def buscar_owner(self):
        self.client.get("/owners/1", name="GET /owners/{id}")

    def listar_vets(self):
        self.client.get(f"{VETS_URL}/vets", name="GET /vets")

    def cadastrar_owner(self):
        sobrenome = f"Locust{uuid.uuid4().hex[:8]}"

        dados = {
            "firstName": "usuario",
            "lastName": sobrenome,
            "address": "Rua Projetada",
            "city": "Cidade",
            "telephone": "89999999999"
        }

        self.client.post("/owners", json=dados, name="POST /owners")


class PerfilLeitura(PetClinicUser):
    @task(45)
    def tarefa_listar_owners(self):
        self.listar_owners()

    @task(35)
    def tarefa_buscar_owner(self):
        self.buscar_owner()

    @task(15)
    def tarefa_listar_vets(self):
        self.listar_vets()

    @task(5)
    def tarefa_cadastrar_owner(self):
        self.cadastrar_owner()


class PerfilEscrita(PetClinicUser):

    @task(20)
    def tarefa_listar_owners(self):
        self.listar_owners()

    @task(20)
    def tarefa_buscar_owner(self):
        self.buscar_owner()

    @task(20)
    def tarefa_listar_vets(self):
        self.listar_vets()

    @task(40)
    def tarefa_cadastrar_owner(self):
        self.cadastrar_owner()
