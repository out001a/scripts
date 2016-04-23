function url_encode()
{
    echo "$(echo "$1" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')"
}
