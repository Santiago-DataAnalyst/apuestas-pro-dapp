# ApuestasPro — Plataforma de Apuestas Descentralizadas (Web3)

Aplicación descentralizada (*dApp*) de mercados de predicción y apuestas bajo esquema **pari-mutuel** sobre Ethereum/EVM. El protocolo permite crear eventos deportivos o de predicción, recibir liquidez transparente en pozos (*pools*) mediante contratos inteligentes en **Solidity**, liquidar resultados y reclamar ganancias proporcionales directamente hacia billeteras **MetaMask** sin custodia intermediaria.

---

## Arquitectura del Proyecto

```text
apuestas-pro-dapp/
├── index.html                        # Interfaz Web3 (Ethers.js + integración MetaMask)
├── iniciar.bat                       # Lanzador automático en 1 clic para Windows
├── iniciar.ps1                       # Orquestador PowerShell (nodo EVM + deploy + servidor web)
└── contrato/
    ├── contracts/
    │   └── apuestas.sol              # Smart Contract ApuestasPro (Solidity ^0.8.19)
    ├── ignition/modules/
    │   └── Apuestas.js               # Módulo de despliegue reproducible con Hardhat Ignition
    ├── test/
    │   └── ApuestasPro.test.js       # Suite de pruebas unitarias (Chai + Ethers v6)
    ├── hardhat.config.js             # Configuración del compilador EVM (Solidity 0.8.28)
    └── package.json                  # Dependencias y scripts de desarrollo
```

---

## Mecánica del Contrato Inteligente (`ApuestasPro`)

1. **Creación de eventos (`crearPartido`):** El administrador registra un evento con identificador único y nombre descriptivo.
2. **Aportación a pozos (`apostar`):** Los participantes envían `ETH` seleccionando la opción `1` (Pozo A) o `2` (Pozo B). Los fondos quedan custodiados en el contrato.
3. **Liquidación (`resolver`):** Al concluir el evento, el administrador certifica la opción ganadora y bloquea nuevas apuestas.
4. **Distribución proporcional (`reclamarPremio`):** Cada ganador retira su capital inicial más su participación proporcional sobre el pozo perdedor:

$$\text{Premio}_i = \text{Aporte}_i + \left( \text{Aporte}_i \times \frac{\text{Pozo}_{\text{perdedor}}}{\text{Pozo}_{\text{ganador}}} \right)$$

El estado del aporte se anula antes de transferir fondos (*checks-effects-interactions*) para prevenir reclamos duplicados.

---

## Requisitos Previos

- **Node.js** `v18+` (incluye `npm` y `npx`)
- **Python 3** (para servir el cliente web estático)
- Extensión **MetaMask** instalada en el navegador (Chrome, Brave o Edge)

---

## Ejecución Rápida

### Opción A: Inicio automático en Windows (1 clic)

Ejecuta `iniciar.bat` desde la raíz del proyecto. El script realiza automáticamente:
1. Instalación de dependencias `npm` si aún no existen.
2. Arranque del nodo local de Hardhat en `http://127.0.0.1:8545` (`Chain ID: 31337`).
3. Despliegue del contrato `ApuestasPro` mediante Hardhat Ignition.
4. Levantamiento del servidor web en `http://localhost:5500` y apertura en el navegador.

### Opción B: Ejecución manual multiplataforma (CLI)

1. **Instalar dependencias y ejecutar pruebas unitarias:**
   ```bash
   cd contrato
   npm install
   npm test
   ```

2. **Iniciar el nodo local EVM:**
   ```bash
   npx hardhat node
   ```

3. **Desplegar el contrato inteligente (en una segunda terminal dentro de `contrato/`):**
   ```bash
   npx hardhat ignition deploy ./ignition/modules/Apuestas.js --network localhost
   ```

4. **Servir el frontend (en la raíz del repositorio):**
   ```bash
   python -m http.server 5500
   ```
   Abre `http://localhost:5500` en tu navegador.

---

## Configuración de MetaMask (Entorno Local)

1. Agrega una red personalizada en MetaMask:
   - **Nombre de red:** `Hardhat Local`
   - **Nueva dirección URL de RPC:** `http://127.0.0.1:8545`
   - **Identificador de cadena (Chain ID):** `31337`
   - **Símbolo de moneda:** `ETH`
2. Importa la **Account #0** mostrada en la consola de `npx hardhat node` para operar con permisos de administrador (crear y liquidar eventos), y opcionalmente **Account #1 / #2** para simular distintos apostadores.

### Ejecución en Red Local (LAN) con múltiples usuarios

Para permitir que otros dispositivos en la misma red Wi-Fi interactúen con el contrato:
1. Inicia el nodo exponiendo la interfaz de red: `npx hardhat node --hostname 0.0.0.0`
2. Despliega el contrato en `localhost` con Hardhat Ignition.
3. Sirve la aplicación web con `python -m http.server 5500 --bind 0.0.0.0`.
4. Los demás usuarios acceden a `http://<IP_DEL_HOST>:5500` y configuran su RPC en MetaMask apuntando a `http://<IP_DEL_HOST>:8545` (`Chain ID: 31337`).

---

## Licencia

Distribuido bajo la licencia **MIT**.
