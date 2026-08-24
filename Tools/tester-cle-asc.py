"""Eprouve le trio cle / identifiant / emetteur contre l'API App Store Connect.

Xcode signale un refus 401 au milieu d'un archivage, sans dire laquelle des
trois valeurs est en cause. Un appel direct le dit en une seconde, et confirme
au passage que la fiche de l'application est visible par la cle.

Ne depend que de la bibliotheque standard et d'openssl : ni PyJWT ni
cryptography ne sont installes sur les executeurs.
"""
import base64, json, subprocess, sys, time, urllib.request, urllib.error


def b64url(donnees: bytes) -> str:
    return base64.urlsafe_b64encode(donnees).rstrip(b'=').decode()


def der_vers_brut(der: bytes) -> bytes:
    """Convertit une signature ECDSA du format DER vers r||s sur 64 octets.

    openssl signe en DER ; JWS attend les deux entiers concatenes, chacun
    complete a gauche sur 32 octets.
    """
    if der[0] != 0x30:
        raise ValueError("signature DER attendue")
    i = 2
    if der[1] & 0x80:                      # longueur sur plusieurs octets
        i = 2 + (der[1] & 0x7F)
    nombres = []
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("entier DER attendu")
        longueur = der[i + 1]
        valeur = der[i + 2:i + 2 + longueur].lstrip(b'\x00')
        nombres.append(valeur.rjust(32, b'\x00'))
        i += 2 + longueur
    return nombres[0] + nombres[1]


def jeton(chemin_cle: str, key_id: str, issuer_id: str) -> str:
    entete = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    maintenant = int(time.time())
    charge = {
        "iss": issuer_id,
        "iat": maintenant,
        "exp": maintenant + 600,           # Apple refuse au-dela de vingt minutes
        "aud": "appstoreconnect-v1",
    }
    a_signer = f"{b64url(json.dumps(entete, separators=(',', ':')).encode())}." \
               f"{b64url(json.dumps(charge, separators=(',', ':')).encode())}"
    der = subprocess.run(
        ['openssl', 'dgst', '-sha256', '-sign', chemin_cle, '-binary'],
        input=a_signer.encode(), capture_output=True, check=True).stdout
    return f"{a_signer}.{b64url(der_vers_brut(der))}"


def main() -> int:
    chemin_cle, key_id, issuer_id = sys.argv[1], sys.argv[2], sys.argv[3]
    attendu = sys.argv[4] if len(sys.argv) > 4 else None

    requete = urllib.request.Request(
        "https://api.appstoreconnect.apple.com/v1/apps?limit=200"
        "&fields[apps]=bundleId,name",
        headers={"Authorization": f"Bearer {jeton(chemin_cle, key_id, issuer_id)}"})
    try:
        with urllib.request.urlopen(requete, timeout=30) as reponse:
            donnees = json.load(reponse)
    except urllib.error.HTTPError as erreur:
        print(f"Apple refuse les identifiants : HTTP {erreur.code}")
        if erreur.code == 401:
            print("  Les trois valeurs sont bien formees mais ne vont pas ensemble,")
            print("  ou la cle a ete revoquee. La cause la plus frequente est un")
            print("  ASC_KEY_ID qui ne correspond pas au .p8 colle : verifiez que")
            print("  les deux viennent bien de la meme cle.")
        return 1

    apps = donnees.get('data', [])
    print(f"Identifiants acceptes. {len(apps)} fiche(s) visible(s) par cette cle.")
    identifiants = [a['attributes'].get('bundleId') for a in apps]
    for app in apps:
        attrs = app['attributes']
        print(f"  {attrs.get('bundleId')}  —  {attrs.get('name')}")
    if attendu and attendu not in identifiants:
        print(f"\nLa fiche '{attendu}' n'est pas visible par cette cle.")
        print("  Verifiez l'identifiant de paquet, ou les droits de la cle.")
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
