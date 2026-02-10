# Postgres helpers (vars in 31_variables.sh).

alias repg="docker stop postgres && docker rm postgres && mkpg postgres"

function mkpg() {
    PG_NAME=$1
    if [ -z "${PG_NAME}" ]; then
      read "PG_NAME?What should this PostgreSQL be called?: "
    fi
    docker run --name ${PG_NAME} -d -p 5432:5432 -e POSTGRES_USER=${PG_NAME} -e POSTGRES_PASSWORD=${PG_NAME} -e POSTGRES_DB=${PG_NAME} postgres
    echo "-------------------------------"
    echo "PostgreSQL is now running with:"
    echo "  database: ${PG_NAME}"
    echo "      user: ${PG_NAME}"
    echo "  password: ${PG_NAME}"
}