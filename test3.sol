// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9;

interface IAnkrETH {
    
    function sharesToBonds(uint256 amount) external view returns (uint256);
}

interface IRateProvider {
    
    function getRate() external view returns (uint256);
}

abstract contract BaseRateProvider is IRateProvider {

    // --- Var ---
    address internal s_token;

    // --- Init ---
    constructor(address _token) {
        s_token = _token;
    }

    // --- View ---
    function getRate() external view virtual override returns (uint256) {
        return IAnkrETH(s_token).sharesToBonds(1e18);
    }
}

contract AnkrETHRateProvider is BaseRateProvider {

    // --- Init ---
    constructor(address _token) BaseRateProvider(_token) {}

    // --- View ---
    function ankrETH() external view returns(address) {
        return s_token;
    }
}
