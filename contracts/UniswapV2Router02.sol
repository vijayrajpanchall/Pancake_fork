pragma solidity =0.6.6;

import './interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import "hardhat/console.sol";

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
   
    event Log(string message, uint val);
    //modifier to check if deadline is expired
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }
     /**
     * @dev Constructor function
     * @param _factory address of the factory
     * @param _WETH address of the WETH
     */
    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

     /**
     * @dev receive function to receive ETH
     * @dev revert if sender is not WETH
     */

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
     // **** ADD LIQUIDITY ****
    /**
     * @dev function to add liquidity
     * @param tokenA address of the tokenA
     * @param tokenB address of the tokenB
     * @param amountADesired amount of tokenA desired
     * @param amountBDesired amount of tokenB desired
     * @param amountAMin minimum amount of tokenA
     * @param amountBMin minimum amount of tokenB
     * @return amountA amount of tokenA
     * @return amountB amount of tokenB
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
     /**
     * @dev function to add liquidity
     * @param tokenA address of the tokenA to add liquidity
     * @param tokenB address of the tokenB to add liquidity
     * @param amountADesired amount of tokenA desired 
     * @param amountBDesired amount of tokenB desired
     * @param amountAMin minimum amount of tokenA
     * @param amountBMin minimum amount of tokenB
     * @param to address to send liquidity to
     * @param deadline deadline for the transaction
     * @return amountA amount of tokenA
     * @return amountB amount of tokenB
     * @return liquidity amount of liquidity
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);

    emit Log("amountA", amountA);
    emit Log("amountB", amountB);
    emit Log("liquidity", liquidity);
    }
    /**
     * @dev function to add liquidity with ETH
     * @param token address of the token to add liquidity
     * @param amountTokenDesired amount of token desired
     * @param amountTokenMin minimum amount of token
     * @param amountETHMin minimum amount of ETH
     * @param to address to send liquidity to
     * @param deadline deadline for the transaction
     * @return amountToken amount of token
     * @return amountETH amount of ETH
     * @return liquidity amount of liquidity
     * @dev amountETH is the amount of ETH sent with the transaction
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    // **** REMOVE LIQUIDITY ****
    /**
     * @dev function to remove liquidity
     * @param tokenA address of the tokenA to remove liquidity
     * @param tokenB address of the tokenB to remove liquidity
     * @param liquidity amount of liquidity to remove
     * @param amountAMin minimum amount of tokenA
     * @param amountBMin minimum amount of tokenB
     * @param to address to send tokens to
     * @param deadline deadline for the transaction
     * @return amountA amount of tokenA
     * @return amountB amount of tokenB
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    /**
     * @dev function to remove liquidity with ETH
     * @param token address of the token to remove liquidity
     * @param liquidity amount of liquidity to remove
     * @param amountTokenMin minimum amount of token
     * @param amountETHMin minimum amount of ETH
     * @param to address to send tokens to
     * @param deadline deadline for the transaction
     * @return amountToken amount of token
     * @return amountETH amount of ETH
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
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
    /**
     * @dev function to remove liquidity with permit
     * @param tokenA address of the tokenA to remove liquidity
     * @param tokenB address of the tokenB to remove liquidity
     * @param liquidity amount of liquidity to remove
     * @param amountAMin minimum amount of tokenA
     * @param amountBMin minimum amount of tokenB
     * @param to address to send tokens to
     * @param deadline deadline for the transaction
     * @param approveMax whether to approve the maximum amount of liquidity
     * @param v signature parameter of the permit
     * @param r signature parameter of the permit
     * @param s signature parameter of the permit
     * @return amountA amount of tokenA
     * @return amountB amount of tokenB
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
     /**
     * @dev function to remove liquidity with ETH with permit
     * @param token address of the token to remove liquidity
     * @param liquidity amount of liquidity to remove
     * @param amountTokenMin minimum amount of token
     * @param amountETHMin minimum amount of ETH
     * @param to address to send tokens to
     * @param deadline deadline for the transaction
     * @param approveMax whether to approve the maximum amount of liquidity
     * @param v signature parameter of the permit
     * @param r signature parameter of the permit
     * @param s signature parameter of the permit
     * @return amountToken amount of token
     * @return amountETH amount of ETH
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    /**
     * @notice internal function to swap an exact amount of tokens for another
     * @param amounts list of amounts to swap
     * @param path list of addresses of tokens to swap
     * @param _to address to send tokens to
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
     /**
     * @notice function to swap an exact amount of tokens for another
     * @param amountIn amount of tokens to swap
     * @param amountOutMin minimum amount of tokens to receive
     * @param path list of addresses of tokens to swap
     * @param to address to send tokens to
     * @param deadline deadline for the transaction
     * @return amounts list of amounts swapped
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        //reduce 2% fee from amount[0] and transfer to treasury address
        uint treasuryFee = amounts[0].mul(2).div(100);
        require(treasuryFee != 0, 'UniswapV2Router: INSUFFICIENT_TREASURY_FEE');
        //transfering treasuryFee to treasury address
        address treasury = IUniswapV2Factory(factory).treasuryad();
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, treasury, treasuryFee
        );
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee));
        _swap(amounts, path, to);
    }
     /**
     * swapTokensForExactTokens is a function that swaps tokens for exact amount of tokens
     * @param amountOut is the amount of tokens to be received
     * @param amountInMax is the maximum amount of tokens to be sent
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     * @return amounts is the array of amounts of tokens to be swapped
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
         amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        uint treasuryFee = amounts[0].mul(2).div(100);
        require(treasuryFee != 0, "treasury fee is 0");
        //transfering treasuryFee to treasury address
        address treasury = IUniswapV2Factory(factory).treasuryad();
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, treasury, treasuryFee
        );
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee)
        );
        _swap(amounts, path, to);
    }
     /**
     * @notice swapExactETHForTokens is a function that swaps exact amount of ETH for tokens
     * @param amountOutMin is the minimum amount of tokens to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     * @return amounts is the array of amounts of tokens to be swapped
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
       require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        // reduce 2% fee from amount[0] and transfer to treasury address
        uint treasuryFee = amounts[0].mul(2).div(100);
        require(treasuryFee != 0, 'UniswapV2Router: INSUFFICIENT_TREASURY_FEE');
        //transfering treasuryFee to treasury address
        address treasury = IUniswapV2Factory(factory).treasuryad();
        IWETH(WETH).transfer(treasury, treasuryFee);
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee)));//
        _swap(amounts, path, to);
    }
    /**
     * @notice swapTokensForExactETH is a function that swaps tokens for exact amount of ETH
     * @param amountOut is the amount of ETH to be received
     * @param amountInMax is the maximum amount of tokens to be sent
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     * @return amounts is the array of amounts of tokens to be swapped
     * @dev path[0] is the address of the token to be swapped
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        //reduce 2% fee from amount[0] and transfer to treasury address
        uint treasuryFee = amounts[0].mul(2).div(100);
        //console.log(amounts[0]);
        require(treasuryFee != 0, 'UniswapV2Router: INSUFFICIENT_TREASURY_FEE');
        //transfering treasuryFee to treasury address
        address treasury = IUniswapV2Factory(factory).treasuryad();
       IWETH(WETH).transfer(treasury, treasuryFee);
       TransferHelper.safeTransferFrom(
           path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee)
       );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
     /**
     * @notice swapExactTokensForETH is a function that swaps exact amount of tokens for ETH
     * @param amountIn is the amount of tokens to be sent
     * @param amountOutMin is the minimum amount of ETH to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     * @return amounts is the array of amounts of tokens to be swapped
     * @dev path[0] is the address of the token to be swapped
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        //reduce 2% fee from amount[0] and transfer to treasury address
        uint treasuryFee = amounts[0].mul(2).div(100);
        //transfering treasuryFee to treasury address

        address treasury = IUniswapV2Factory(factory).treasuryad();

        IWETH(WETH).transfer(treasury, treasuryFee);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee)
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    /**
     * @notice swapETHForExactTokens is a function that swaps ETH for exact amount of tokens
     * @param amountOut is the amount of tokens to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     * @return amounts is the array of amounts of tokens to be swapped
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
         require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        //reduce 2% fee from amount[0] and transfer to treasury address
        uint treasuryFee = amounts[0].mul(2).div(100);
        //transfering treasuryFee to treasury address
        address treasury = IUniswapV2Factory(factory).treasuryad();
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, treasury, treasuryFee
        );
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0].sub(treasuryFee)));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0] - treasuryFee);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
     /**
     * @notice _swapSupportingFeeOnTransferTokens is a function that swaps tokens supporting fee on transfer tokens
     * @param path is the array of addresses of tokens to be swapped
     * @param _to is the address of the receiver
     */
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
     /**
     * @notice swapExactTokensForTokensSupportingFeeOnTransferTokens is a function
     * that swaps exact amount of tokens for tokens supporting fee on transfer tokens
     * @param amountIn is the amount of tokens to be swapped
     * @param amountOutMin is the minimum amount of tokens to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
      /**
     * @notice swapExactETHForTokensSupportingFeeOnTransferTokens is a function
     * that swaps exact amount of ETH for tokens supporting fee on transfer tokens
     * @param amountOutMin is the minimum amount of tokens to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
      /**
     * @notice swapExactTokensForETHSupportingFeeOnTransferTokens is a function
     * that swaps exact amount of tokens for ETH supporting fee on transfer tokens
     * @param amountIn is the amount of tokens to be swapped
     * @param amountOutMin is the minimum amount of ETH to be received
     * @param path is the array of addresses of tokens to be swapped
     * @param to is the address of the receiver
     * @param deadline is the time after which the transaction will be reverted
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
     /**
     * @notice quote is a function that returns the amount of output tokens
     * that would be received for a given amount of input tokens
     * @param amountA is the amount of input tokens
     * @param reserveA is the amount of input tokens in the pool
     * @param reserveB is the amount of output tokens in the pool
     */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }
    /**
     * @notice getAmountOut is a function that returns the amount of output tokens
     * that would be received for a given amount of input tokens
     * @param amountIn is the amount of input tokens
     * @param reserveIn is the amount of input tokens in the pool
     * @param reserveOut is the amount of output tokens in the pool
     * @return amountOut is the amount of output tokens
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }
     /**
     * @notice getAmountIn is a function that returns the amount of input tokens
     * that would be needed to receive a given amount of output tokens
     * @param amountOut is the amount of output tokens
     * @param reserveIn is the amount of input tokens in the pool
     * @param reserveOut is the amount of output tokens in the pool
     * @return amountIn is the amount of input tokens
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }
     /**
     * @notice getAmountsOut is a function that returns the amount of output tokens
     * that would be received for a given amount of input tokens
     * @param amountIn is the amount of input tokens
     * @param path is the array of addresses of tokens to be swapped
     * @return amounts is the array of amounts of tokens to be received
     */
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }
     /**
     * @notice getAmountsIn is a function that returns the amount of input tokens
     * that would be needed to receive a given amount of output tokens
     * @param amountOut is the amount of output tokens
     * @param path is the array of addresses of tokens to be swapped
     * @return amounts is the array of amounts of tokens to be received
     */
    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
