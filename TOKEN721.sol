//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CONTRACTS/ERC165.sol";
import "./INTERFACES/IERC721.sol";
import "./INTERFACES/IERC721Receiver.sol";

contract TOKEN721 is ERC165 , IERC721{
    //VARIABLES DE ESTADO
    //Quien es el dueño del token
    mapping(uint256 => address) private _owners;
    //Cuantos token tiene una adress
    mapping(address => uint256) private _balance;
    //Relacion de los token con las address aprovadas para su gestion
    mapping(uint256 => address) private _tokenApprovals;
    //Relacion de address que pueden gestionar token de otras address
    mapping(address => mapping(address =>bool)) private _operatorApprovals;//El primero es el dueño de la address y el segundo maping , las direcciones que tienen permitido el manejo de sus tokens

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165, IERC165) returns (bool){
        return interfaceID == type(IERC721).interfaceId || super.supportsInterface(interfaceID);
    }

    //Funcion para saber el balance de una cuenta
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721 ERROR: Address Vacia");
        return _balance[owner];
    }
    //Funcion para saber el dueño de un token
    function ownerOf(uint256 tokenId) public view override returns (address){
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721 ERROR: No existe el token;");
        return owner;
    }
    //Permitir que alguien que no sea dueño del token, pueda gestionarlo
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721 ERROR: La address de destino debe ser diferente a la de envio");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721 ERROR: No tienes permisos para gestionar este token");
        _approve(to, tokenId);
    }

    //Funcion interna para aprovar a una address que gestione un token que no es de su propiedad
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    //Dar permisos a una address para que pueda gestionar todos los token de otra addess
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721 ERROR: No te puedes dar permisos a ti mismo");

        _operatorApprovals[msg.sender][operator] = approved; //Añadimos en el mapping los permisos para el operador
        emit ApprovalForAll(msg.sender, operator, approved); //Enviamos evento 
    }

    //Saber quien puede gestionar un token
    function getApproved(uint256 tokenId) public view virtual override returns (address){
        require(_exists(tokenId), "ERC721 ERROR: El token no existe");

        return _tokenApprovals[tokenId]; //Devolvemos el operador que tiene permitido gestionar ese token
    }

    //Saber si una direccion (operador) tiene permiso de manejar todos los tokens de otra direccion (owner)
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator]; //Miramos en el mapping si el operador tiene derecho de gestionar todos los tokens del dueño de los tokens
    }

    //Funcion para hacer una transgerencia segura , sin el parametro data
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override{
        safeTransferFrom(from, to, tokenId, "");
    }
    //Funcion para hacer una transferencia de un token de forma segura
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override{
        require(_isApprovedOrOwner(msg.sender, tokenId), ""); //Comprobamos Que el que llama a la funcion de transferencia, tenga permisos sobre el token

        _safeTransfer(from, to , tokenId, _data);
    } 
    //Funcion que realiza la transferencia comprobando que si es un contrato quien lo recibe y no una address externa, sea compatible con el standard erc721
    //En caso de no serlo, se revertira la transferencia para que no se queme el token
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual{
        _transfer(from, to, tokenId);
        require(_chekOnERC721Received(from, to, tokenId, _data), "ERC721 ERROR: El destino no admite este estandar");
    }

    //
    function transferFrom(address from , address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "");
        _transfer(from, to , tokenId);
    }

    //Funcion interna para realizar la transferencia de token que sera llamada despues de hacer las comprobaciones necesarias
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721 ERROR: No existe ese token");
        require(to != address(0), "");

        _balance[from] -= 1;
        _balance[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    //Funcion para hacer el mint con seguridad,en este caso sin el parametro "_data". Lo que hace es llamar a la funcion safeMint pasandole el parametro data como un string vacío
    function _safeMint(address to, uint256 tokenId) public{
        _safeMint(to, tokenId, "");
    }

    //Funcion para hacer el mint con seguridad, comprobando que sea compatible con la address que lo recibe
    function _safeMint(address to, uint256 tokenId, bytes memory _data)public{
        _mint(to, tokenId);
        //La funcion _chekOnERC721Received comprueba que, si la dirección que va a recibir el token es de contrato, sea compatible con este estandar para que no se queme el token. En caso de no serlo, revertira la transaccion
        require(_chekOnERC721Received(address(0), to, tokenId, _data), "ERC721 ERROR: Transferencia no implementada en IERC721Receiver");
    }

    //Funcion interna para crear un nft nuevo  y añadirselo a la cartera que lo mintea
    function _mint(address to, uint256 tokenId) internal virtual{
        require(to != address(0), "");
        require(!_exists(tokenId), "ERC721 ERROR: El token ya ha sido minteado");

        _beforeTokenTransfer(address(0), to, tokenId );

        _balance[to] += 1;
        _owners[tokenId] = to;
        //Como el token no existe y se esta creando, la dirección de envio de la transferencia es la dirección 0
        emit Transfer(address(0), to, tokenId);
    }

    //Funcion que comprueba que la direccion de envio no sea un contrato, y si lo es, comprueba que permita el standard ERC721   
    function _chekOnERC721Received(address from , address to, uint256 tokenId, bytes memory _data) private returns (bool){
        if(isContract(to)){
            try IERC721Receiver(to).onERC721Receiver(msg.sender, from, tokenId, _data) returns (bytes4 retval){
                return retval == IERC721Receiver(to).onERC721Receiver.selector;
            }catch(bytes memory reason){
                if(reason.length == 0) {
                    revert("ERC721 ERROR, transferencia no implementada para ese contrato");
                }else{
                    //solhint-disable-next-line no-inline-assembly
                    assembly{
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }else{
            return true;
        }
    }

    //Funcion para saber si la direccion que recibe por parametros es un contrato
    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly{
            size :=extcodesize(_addr) //Obtenemos el tamaño del codigo ya que si es un smart contract, tendra tamaño, si no , sera 0
        }
        return (size > 0);
    }

    //Funcion intern para saber si existe un token
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId]!= address(0); //Si el token tiene dueño, devolvera true, si no , sera false
    }

    //Funcion en la que incluiriamos lo que queramos hacer antes de enviar un token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    //Funcion interna para saber si alguien tiene permisos para gestionar un token o si es el dueño
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool){
        require(_exists(tokenId), "ERC721 ERROR: No existe el token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId)==spender || isApprovedForAll(owner, spender));
    }
}
