// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.6;

import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeFactory.sol";
import "./libraries/PancakeLibrary.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";

contract PancakeRouter is IPancakeRouter02 {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;

    struct Swap {
        address tokenToSwap;
        address tokenToReceive;
        uint256 amountToSwap;
        uint256 amountToReceive;
        uint256 slippageTolerance;
        uint256 swapId;
        bool isSwapInitiated;
        bool isSwapConfirmed;
    }

    mapping(uint256 => Swap) public swaps;

    event SwapInitiated(
        address tokenToSwap,
        address tokenToReceive,
        uint256 amountToSwap,
        uint256 amountToReceive,
        uint256 slippageTolerance,
        uint256 swapId
    );

    event SwapConfirmed(
        address tokenToSwap,
        address tokenToReceive,
        uint256 amountToSwap,
        uint256 amountToReceive,
        uint256 slippageTolerance,
        uint256 swapId
    );

    event SwapCancelled(
        address tokenToSwap,
        address tokenToReceive,
        uint256 amountToSwap,
        uint256 amountToReceive,
        uint256 slippageTolerance,
        uint256 swapId
    );

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "PancakeRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "PancakeRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "PancakeRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPancakePair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IPancakePair(pair).burn(to);
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "PancakeRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "PancakeRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPancakePair(PancakeLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    //  initiateSwap: This function should be called by the user who wants to initiate a token swap. The function should take as input the amount of tokens to be swapped, the address of the token being swapped, the address of the token to be received, and the slippage tolerance.
    function initiateSwap(
        address _tokenToSwap,
        address _tokenToReceive,
        uint256 _amountToSwap,
        uint256 _slippageTolerance
    ) public {
        require(_tokenToSwap != address(0), "Invalid token address");
        require(_tokenToReceive != address(0), "Invalid token address");
        require(_amountToSwap > 0, "Invalid amount");
        require(_slippageTolerance > 0, "Invalid slippage tolerance");

                uint256 swapId = block.timestamp;

        Swap memory swap = Swap({
            tokenToSwap: _tokenToSwap,
            tokenToReceive: _tokenToReceive,
            amountToSwap: _amountToSwap,
            amountToReceive: 0,
            slippageTolerance: _slippageTolerance,
            swapId: swapId,
            isSwapInitiated: true,
            isSwapConfirmed: false
        });

        swaps[swapId] = swap;

        emit SwapInitiated(
            _tokenToSwap,
            _tokenToReceive,
            _amountToSwap,
            0,
            _slippageTolerance,
            swapId
        );
    }

    //  confirmSwap: This function should be called by the user who wants to confirm a token swap. The function should take as input the swapId of the swap to be confirmed.
    function confirmSwap(uint256 _swapId) public {
        require(swaps[_swapId].isSwapInitiated, "Swap not initiated");
        require(!swaps[_swapId].isSwapConfirmed, "Swap already confirmed");

        uint256 amountToReceive =
            (swaps[_swapId].amountToSwap * (100 - swaps[_swapId].slippageTolerance)) / 100;

        address[] memory path = new address[](2);
        path[0] = swaps[_swapId].tokenToSwap;
        path[1] = swaps[_swapId].tokenToReceive;

        uint256[] memory amounts = PancakeLibrary.getAmountsOut(factory, swaps[_swapId].amountToSwap, path);

        require(amounts[1] >= amountToReceive, "Slippage tolerance too high");

        TransferHelper.safeTransferFrom(
            swaps[_swapId].tokenToSwap,
            msg.sender,
            PancakeLibrary.pairFor(factory, path[0], path[1]),
            swaps[_swapId].amountToSwap
        );

        _swap(amounts, path, msg.sender);

        swaps[_swapId].amountToReceive = amounts[1];
        swaps[_swapId].isSwapConfirmed = true;

        emit SwapConfirmed(
            swaps[_swapId].tokenToSwap,
            swaps[_swapId].tokenToReceive,
            swaps[_swapId].amountToSwap,
            swaps[_swapId].amountToReceive,
            swaps[_swapId].slippageTolerance,
            _swapId
        );
    }

    //  cancelSwap: This function should be called by the user who wants to cancel a token swap. The function should take as input the swapId of the swap to be cancelled.
    function cancelSwap(uint256 _swapId) public {
        require(swaps[_swapId].isSwapInitiated, "Swap not initiated");
        require(!swaps[_swapId].isSwapConfirmed, "Swap already confirmed");

        swaps[_swapId].isSwapInitiated = false;

        emit SwapCancelled(
            swaps[_swapId].tokenToSwap,
            swaps[_swapId].tokenToReceive,
            swaps[_swapId].amountToSwap,
            0,
            swaps[_swapId].slippageTolerance,
            _swapId
        );
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return PancakeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return PancakeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return PancakeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PancakeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PancakeLibrary.getAmountsIn(factory, amountOut, path);
    }
}
