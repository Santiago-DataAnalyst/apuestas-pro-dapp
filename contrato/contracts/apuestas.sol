// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ApuestasPro {
    address public admin;
    
    struct Partido {
        string nombre;
        uint256 pozoA;
        uint256 pozoB;
        bool finalizado;
        uint8 ganador; // 1 para A, 2 para B
    }

    mapping(uint256 => Partido) public partidos;
    mapping(uint256 => mapping(address => mapping(uint8 => uint256))) public aportes;

    constructor() { admin = msg.sender; }

    function crearPartido(uint256 _id, string memory _nombre) external {
        require(msg.sender == admin, "No autorizado");
        require(bytes(_nombre).length > 0, "Nombre requerido");
        require(bytes(partidos[_id].nombre).length == 0, "Partido ya existe");
        partidos[_id] = Partido(_nombre, 0, 0, false, 0);
    }

    function apostar(uint256 _id, uint8 _opcion) external payable {
        Partido storage p = partidos[_id];
        require(bytes(p.nombre).length > 0, "Partido no existe");
        require(!p.finalizado, "Cerrado");
        require(msg.value > 0, "Monto debe ser mayor a 0");
        require(_opcion == 1 || _opcion == 2, "Opcion invalida");

        if(_opcion == 1) p.pozoA += msg.value;
        else p.pozoB += msg.value;

        aportes[_id][msg.sender][_opcion] += msg.value;
    }

    function resolver(uint256 _id, uint8 _ganador) external {
        require(msg.sender == admin, "Solo admin");
        Partido storage p = partidos[_id];
        require(bytes(p.nombre).length > 0, "Partido no existe");
        require(!p.finalizado, "Ya finalizado");
        require(_ganador == 1 || _ganador == 2, "Ganador invalido");
        p.ganador = _ganador;
        p.finalizado = true;
    }

    function reclamarPremio(uint256 _id) external {
        Partido storage p = partidos[_id];
        require(p.finalizado, "Partido en curso");
        
        uint8 g = p.ganador;
        uint256 miApuestaGadora = aportes[_id][msg.sender][g];
        require(miApuestaGadora > 0, "No ganaste nada");

        uint256 pozoGanador = (g == 1) ? p.pozoA : p.pozoB;
        uint256 pozoPerdedor = (g == 1) ? p.pozoB : p.pozoA;

        uint256 premio = miApuestaGadora + (miApuestaGadora * pozoPerdedor / pozoGanador);
        
        aportes[_id][msg.sender][g] = 0; 
        payable(msg.sender).transfer(premio);
    }
}