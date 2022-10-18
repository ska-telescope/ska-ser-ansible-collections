import os
import json
import requests
import pymysql.cursors
from kubernetes import client, config

archiver_ip = os.getenv("ARCHIVER_IP")
archiver_user = os.getenv("ARCHIVER_USER")
archiver_password = os.getenv("ARCHIVER_PASSWORD")
archiver_default_db = os.getenv("ARCHIVER_DEFAULT_DB")

grafana_host = os.getenv("GRAFANA_HOST")
grafana_port = os.getenv("GRAFANA_PORT")
grafana_user = os.getenv("GRAFANA_USER")
grafana_password = os.getenv("GRAFANA_PASSWORD")

k8s_loadbalancer = os.getenv("K8S_LOADBALANCER")
k8s_master = os.getenv("K8S_MASTER")

tangodb_password = os.getenv("TANGODB_PASSWORD")


def get_databases():
    db = []
    connection = pymysql.connect(
        host=archiver_ip,
        user=archiver_user,
        password=archiver_password,
        database=archiver_default_db,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )

    with connection:
        with connection.cursor() as cursor:
            sql = "show databases"
            cursor.execute(sql)
            result = cursor.fetchall()
            for res in result:
                if not (
                    "tango" in res["Database"]
                    or "mysql" in res["Database"]
                    or "information_schema" in res["Database"]
                ):
                    db.append(res["Database"])

    return db


# return namespace-tango_host name dicationary
def get_active_namespaces(list_service_for_all_namespaces):
    result = {}
    for item in list_service_for_all_namespaces.items:
        if "tangodb" not in item.metadata.name:
            continue

        if item.metadata.namespace not in result:
            result[
                item.metadata.namespace
            ] = f"{k8s_master}:{item._spec._ports[0].node_port}"

    return result


grafana_url = os.path.join(
    "http://",
    "%s:%s@%s:%s"
    % (grafana_user, grafana_password, grafana_host, grafana_port),
)
session = requests.Session()
# Get list of configured datasources in grafana
datasources_get = session.get(os.path.join(grafana_url, "api", "datasources"))
datasources = datasources_get.json()
# Insert Archiver DBs
available_dbs = get_databases()
for db in available_dbs:
    present = False
    for datasource in datasources:
        if db in datasource["database"]:
            present = True
            break

    if not present:
        print("inserting archiver data source" + db)
        datasources_put = session.post(
            os.path.join(grafana_url, "api", "datasources"),
            data=json.dumps(
                {
                    "name": f"Archiver({db})",
                    "type": "mysql",
                    "typeLogoUrl": (
                        "public/app/plugins/"
                        "datasource/mysql/img/mysql_logo.svg"
                    ),
                    "access": "proxy",
                    "url": f"{archiver_ip}:3306",
                    "password": "",
                    "secureJsonData": {"password": archiver_password},
                    "user": archiver_user,
                    "database": db,
                    "basicAuth": False,
                    "isDefault": False,
                    "jsonData": {},
                    "readOnly": False,
                }
            ),
            headers={"content-type": "application/json"},
        )
        if not datasources_put.status_code == requests.codes.ok:
            print(datasources_put.json())
# End Insert Archiver DBs

# Insert/Update TangoGQL/TangoDB
config.load_kube_config()
core_v1_api = client.CoreV1Api()
all_svc = core_v1_api.list_service_for_all_namespaces()
active_namespaces = get_active_namespaces(all_svc)

# Remove old
for datasource in datasources:
    bool_tango_gql = datasource["type"] == "fifemon-graphql-datasource"
    bool_tangodb = "TangoDB" in datasource["name"]
    bool_archiver = "Archiver" in datasource["name"]

    if not (bool_tango_gql or bool_tangodb or bool_archiver):
        continue

    present = False
    for active_namespace in active_namespaces:
        if bool_tango_gql and active_namespace in datasource["url"]:
            present = True
            break

        if (
            bool_tangodb
            and active_namespaces[active_namespace] == datasource["url"]
        ):
            present = True
            break

        if bool_archiver and (datasource["database"] in available_dbs):
            present = True
            break

    if not present:
        print(f"deleting {datasource['name']}: not available")
        delete_res = session.delete(
            os.path.join(
                grafana_url, "api", "datasources", str(datasource["id"])
            )
        )
        if not delete_res.status_code == requests.codes.ok:
            print(delete_res.json())

# End Remove old

# Insert new
for active_namespace in active_namespaces:
    bool_TangoGql_present = False
    bool_TangoDB_present = False
    for datasource in datasources:
        if (
            datasource["type"] == "fifemon-graphql-datasource"
            and active_namespace in datasource["url"]
        ):
            print(f"TangoGql for {active_namespace}: present")
            bool_TangoGql_present = True

        if (
            datasource["type"] == "mysql"
            and active_namespaces[active_namespace] == datasource["url"]
        ):
            print(f"TangoDB for {active_namespace}: present")
            bool_TangoDB_present = True

    if not bool_TangoGql_present:
        print(
            f"insert TANGOGQL for {active_namespace}"
            f":TANGOGQL ({active_namespace})"
        )
        datasources_put = session.post(
            os.path.join(grafana_url, "api", "datasources"),
            data=json.dumps(
                {
                    "name": f"TangoGQL ({active_namespace})",
                    "type": "fifemon-graphql-datasource",
                    "typeLogoUrl": (
                        "public/plugins/"
                        "fifemon-graphql-datasource/img/logo.svg"
                    ),
                    "access": "proxy",
                    "url": (
                        f"http://{k8s_loadbalancer}/"
                        f"{active_namespace}/taranta/db"
                    ),
                    "password": "",
                    "user": "",
                    "database": "",
                    "basicAuth": True,
                    "isDefault": False,
                    "jsonData": {},
                    "readOnly": False,
                }
            ),
            headers={"content-type": "application/json"},
        )
        if not datasources_put.status_code == requests.codes.ok:
            print(datasources_put.json())

    if not bool_TangoDB_present:
        print(
            (
                f"insert TangoDB for {active_namespace}: "
                f"{active_namespaces[active_namespace]}"
            )
        )
        datasources_put = session.post(
            os.path.join(grafana_url, "api", "datasources"),
            data=json.dumps(
                {
                    "name": f"TangoDB({active_namespace})",
                    "type": "mysql",
                    "typeLogoUrl": (
                        "public/app/plugins/"
                        "datasource/mysql/img/mysql_logo.svg"
                    ),
                    "access": "proxy",
                    "url": f"{active_namespaces[active_namespace]}",
                    "password": "",
                    "secureJsonData": {"password": tangodb_password},
                    "user": "root",
                    "database": "tango",
                    "basicAuth": False,
                    "isDefault": False,
                    "jsonData": {},
                    "readOnly": False,
                }
            ),
            headers={"content-type": "application/json"},
        )
        if not datasources_put.status_code == requests.codes.ok:
            print(datasources_put.json())

# End Insert new
