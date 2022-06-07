//SPDX-License-Identifier: GPL-3.0;

pragma solidity >=0.7.0 <0.9.0;

//import '.SafeMath.sol';
//Son 2 contratos: crowdfunding (recoge todos los proyectos generados) y Proyecto (bóveda de cada proyecto).

contract Crowdfunding {
    //Lista de proyectos existentes
    Proyecto[] private proyectos;
    // Evento que se inicia cada vez que hay un proyecto nuevo
    event proyectoIniciado(address addressContrato, address adressProyecto, string tituloProyecto,string descripcionProyecto, uint256 plazo, uint256 cantidadObjetivo);

    function inicioProyecto(
        string calldata titulo,
        string calldata descripcion,
        uint32 _inicio,
        uint32 _final,    
        uint cantidadARecaudar
    ) external {
        require(_inicio >= block.timestamp, "inicio < now");
        require(_final >= block.timestamp, "final < inicio");
        require(_final <= block.timestamp + 60 days, "final > duracion max");


        //HACEMOS LOS CALCULOS PARA QUE SEA MAS SENCILLO EN DIAS DIRECTAMENTE
        //Revisar que pasa con los días, si hay que declararlo, si es DAYS
        //uint256 recaudarHasta = block.timestamp + duracionEnDias * 1 dias;
        uint256 recaudarHasta = block.timestamp + 60 days;
        

        Proyecto nuevoProyecto = new Proyecto(msg.sender, titulo, descripcion, recaudarHasta, cantidadARecaudar);
       proyectos.impulsar(nuevoProyecto);
        emit proyectoIniciado( address(nuevoProyecto),msg.sender,titulo, descripcion, recaudarHasta, cantidadARecaudar);
        
    }                                                                                                                                   

    function listaTodosProyectos() external view returns(Proyecto[] memory){
        return proyectos;
    }
}

contract Proyecto {
    //using SafeMath for uint256;
    
    
    enum Estado {
        RecaudacionDeFondos,
        Vencido,
        Exitoso
    }
    //Variables estado
    address payable public creador;
    uint public cantidadObjetivo; 
    uint public completo;
    uint256 public balanceActual;
    uint public aumentado;
    string public titulo;
    string public descripcion;
    Estado public estado = Estado.RecaudacionDeFondos; 
    mapping (address => uint) public contribuciones;

    //Evento que se emitirá cada vez que se reciba financiación
    event FondosRecibidos(address donante, uint cantidad, uint saldoTotal);
    //Evento que se emitirá cada vez que el iniciador del proyecto haya recibido los fondos
    event pagoCreador(address beneficiario);

    //Modifier para comprobar el estado actual del beneficiario
    modifier inEstado(Estado _estado) {
        require(estado == _estado);
        _;
    }
    // Modifier para verificar si la persona que llama a la función es el creador del proyecto.
    modifier isCreador() {
        require(msg.sender == creador);
        _;
    }

    constructor (address payable adressProyecto, string memory tituloProyecto, string memory descripcionProyecto, uint plazoRecaudacionFondos, uint cantidadObjetivo) public {
        creador = adressProyecto;
        titulo = tituloProyecto;
        descripcion = descripcionProyecto;
        objetivo = cantidadObjetivo;
        fechaLimite = plazoRecaudacionFondos;
        balanceActual = 0;
    }

    
    function donar() external inEstado(Estado.RecaudacionDeFondos) payable {
        require(msg.sender != creador);
        contribuciones[msg.sender] = contribuciones[msg.sender].add(msg.value);
        balanceActual = balanceActual.add(msg.value);
        emit FondosRecibidos(msg.sender, msg.value, balanceActual);
        comprobarSiLaRecaudacionCompletoOVencido();
    }

    //Funcion para comporbar si cambiamos de fase
    function comprobarSiLaRecaudacionCompletoOVencido() public {
        if (balanceActual >= objetivo) {
            estado = Estado.Exitoso;
            pagar();
        } else if (block.timestamp > fechaLimite)  {
            estado = Estado.Vencido;
        }
        completo = block.timestamp;
    }


    function pagar() internal inEstado(Estado.Exitoso) returns (bool) {
        uint256 totalRecaudado = balanceActual;
        balanceActual = 0;

        if (creador.send(totalRecaudado)) {
            emit pagoCreador(creador);
            return true;
        } else {
            balanceActual = totalRecaudado;
            estado = Estado.Exitoso;
        }

        return false;
    }

    //Funcion de claim para repartir la cantidad recaudada en 12 partes iguales, una por cada mes del año
    //function claim() external {
        //require proyecto
  

  
    function obtenerDetalles() public view returns(
        address payable adressProyecto,
        string memory tituloProyecto,
        string memory descripcionProyecto,
        uint256 plazo,
        Estado estadoActual,
        uint256 cantidadActual,
        uint256 cantidadObjetivo
    ){
        adressProyecto = creador;
        tituloProyecto = titulo;
        descripcionProyecto = descripcion;
        plazo = fechaLimite;
        estadoActual = estado;
        cantidadActual = balanceActual;
        cantidadObjetivo = objetivo;

    }
    
  }  
       
