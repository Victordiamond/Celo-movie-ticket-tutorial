// SPDX-License-Identifier: MIT

// Specify the version of Solidity used in this contract
pragma solidity >=0.8.0;

// Import the Ownable contract from the OpenZeppelin library
import "@openzeppelin/contracts/access/Ownable.sol";

// Import the ERC20 interface from the OpenZeppelin library
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Define the MovieTickets contract and inherit from the Ownable contract
// Define a struct to represent a movie ticket
struct MovieTicket {
    address payable admin;
    string name;
    string image;
    string filmIndustry;
    string genre;
    string description;
    uint price;
    uint sold;
    uint ticketsAvailable;
    bool forSale;
}

// Define private variables for tracking movies, user tickets, and revenue
uint private moviesLength;
address private cUsdTokenAddress;
mapping (uint => MovieTicket) private movies;
mapping (address => mapping (uint => uint)) private userTickets;
uint private totalRevenue;

// Define events to emit when tickets are purchased or refunded
event TicketPurchase(address indexed buyer, uint indexed movieIndex, uint ticketCount);
event TicketRefund(address indexed buyer, uint indexed movieIndex, uint ticketCount);

// Define a modifier to check if there are enough tickets available for purchase
modifier isTicketAvailable(uint _index, uint _tickets) {
    require(movies[_index].ticketsAvailable >= _tickets, "Tickets not sufficient");
    _;
}

// Define a modifier to check if a ticket is for sale
modifier isTicketForSale(uint _index) {
    require(movies[_index].forSale == true, "Ticket is not for sale");
    _;
}

// Define a modifier to check if the caller is an admin for a movie
modifier isAdmin(uint _index) {
    require(msg.sender == movies[_index].admin, "Only admin");
    _;
}

// Define a constructor to set the cUSD token address
constructor(address _cUsdTokenAddress) {
    cUsdTokenAddress = _cUsdTokenAddress;
}

// Define a function to add a new movie
function addMovie(
    string memory _name,
    string memory _image,
    string memory _filmIndustry,
    string memory _genre,
    string memory _description,
    uint _price,
    uint _ticketsAvailable
) external onlyOwner {
    uint _sold = 0;
    movies[moviesLength] = MovieTicket(
        payable(msg.sender),
        _name,
        _image,
        _filmIndustry,
        _genre,
        _description,
        _price,
        _sold,
        _ticketsAvailable,
        true
    );
    moviesLength++;
}

// Define a function to get information about a movie ticket
function getMovieTicket(uint _index) external view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    string memory,
    string memory,
    uint,
    uint,
    uint,
    bool
) {
    MovieTicket memory m = movies[_index];
    return (
        m.admin,
        m.name,
        m.image,
        m.filmIndustry,
        m.genre,
        m.description,
        m.price,
        m.sold,
        m.ticketsAvailable,
        m.forSale
    );
}

// Define a function to add tickets to a movie
function addTickets(uint _index, uint _tickets) external isAdmin(_index) {
    require(_tickets > 0, "Number of tickets must be greater than zero");
    movies[_index].ticketsAvailable += _tickets;
}

function changeForSale(uint _index) external isAdmin(_index) {
    movies[_index].forSale = !movies[_index].forSale;
}

// Define a function to remove tickets
function removeTicket(uint _index) external isAdmin(_index) {
    movies[_index] = movies[moviesLength - 1];
    delete movies[moviesLength - 1];
    moviesLength--;
}

function blockTickets(uint _index, uint _tickets) external isAdmin(_index) isTicketAvailable(_index, _tickets) {
    movies[_index].ticketsAvailable -= _tickets;
}

// Define a function to buy bulk tickets
function buyBulkMovieTicket(uint _index, uint _tickets) external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
) external payable isTicketForSale(_index) isTicketAvailable(_index, _tickets) {
require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
require(
IERC20(cUsdTokenAddress).transferFrom(
msg.sender,
movies[_index].admin,
movies[_index].price * _tickets
),
"Transfer failed."
);    movies[_index].sold += _tickets;
    movies[_index].ticketsAvailable -= _tickets;
    userTickets[msg.sender][_index] += _tickets;

    totalRevenue += movies[_index].price * _tickets;

    emit TicketPurchase(msg.sender, _index, _tickets);
}

function buyMovieTicket(uint _index) public payable isTicketForSale(_index) isTicketAvailable(_index, 1) {
    require(msg.sender != movies[_index].admin, "Admin cannot buy tickets");
    require(
        IERC20(cUsdTokenAddress).transferFrom(
            msg.sender,
            movies[_index].admin,
            movies[_index].price
        ),
        "Transfer failed."
    );

    movies[_index].sold += 1;
    movies[_index].ticketsAvailable -= 1;
    userTickets[msg.sender][_index] += 1;

    totalRevenue += movies[_index].price;

    emit TicketPurchase(msg.sender, _index, 1);
}

// Define a function to refund tickets
function refundTickets(uint _index, uint _tickets) external {
    require(_tickets > 0, "Number of tickets must be greater than zero");
    require(userTickets[msg.sender][_index] >= _tickets, "Insufficient tickets for refund");

    uint refundAmount = movies[_index].price * _tickets;

    require(
        IERC20(cUsdTokenAddress).transferFrom(
            movies[_index].admin,
            msg.sender,
            refundAmount
        ),
        "Transfer failed."
    );

    movies[_index].sold -= _tickets;
    movies[_index].ticketsAvailable += _tickets;
    userTickets[msg.sender][_index] -= _tickets;

    totalRevenue -= refundAmount;

    emit TicketRefund(msg.sender, _index, _tickets);
}

function getTicketsLength() public view returns (uint) {
    return moviesLength;
}

function getUserTickets(address _user, uint _index) public view returns (uint) {
    return userTickets[_user][_index];
}

function getTotalRevenue() public view returns (uint) {
    return totalRevenue;
}
}
