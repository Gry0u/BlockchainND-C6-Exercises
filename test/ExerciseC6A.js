
var Test = require('../config/testConfig.js')

contract('ExerciseC6A', async (accounts) => {

  var config
  before('setup contract', async () => {
    config = await Test.Config(accounts)
  })
/*
  it('contract owner can register new user', async () => {

    // ARRANGE
    let caller = accounts[0] // This should be config.owner or accounts[0] for registering a new user
    let newUser = config.testAddresses[0]
    // ACT
    await config.exerciseC6A.registerUser(newUser, false, { from: caller })
    let result = await config.exerciseC6A.isUserRegistered.call(newUser)

    // ASSERT
    assert.equal(result, true, 'Contract owner cannot register new user')
  })
  it('contract owner can pause the contract', async () => {
    // ARRANGE
    let caller = accounts[0]
    let operationalInit = await config.exerciseC6A.operational.call()
    const test = await config.exerciseC6A.userProfiles(caller)
    console.log(test)

    await config.exerciseC6A.setOperatingStatus(false, { from: caller })
    let operationalPaused = await config.exerciseC6A.operational.call()

    assert.equal(operationalInit, true, 'Contract not operational at start')
    assert.equal(operationalPaused, false, 'Contract was not paused')

    // TEST IF NO LOCKOUT BUG!
    await config.exerciseC6A.setOperatingStatus(true, { from: caller })
    let operationalBackOn = await config.exerciseC6A.operational.call()
    assert.equal(operationalBackOn, true, 'Lock Out bug')

    // ONCE contract is pause, can't register user anymore
    let newUser2 = config.testAddresses[1]
    try {
      await config.exerciseC6A.registerUser(newUser2, false, { from: caller })
    } catch (error) {
      assert(error.message.includes('Contract is currently not operational', 'Error'))
    }
  })
*/
  it('function call is made when multi-party threshold is reached', async () => {
    // add 5 admins
    let admin1 = accounts[1]
    let admin2 = accounts[2]
    let admin3 = accounts[3]
    let admin4 = accounts[4]
    let admin5 = accounts[5]

    await config.exerciseC6A.registerUser(admin1, true, { from: config.owner })
    await config.exerciseC6A.registerUser(admin2, true, { from: config.owner })
    await config.exerciseC6A.registerUser(admin3, true, { from: config.owner })
    await config.exerciseC6A.registerUser(admin4, true, { from: config.owner })
    await config.exerciseC6A.registerUser(admin5, true, { from: config.owner })
    assert(await config.exerciseC6A.userProfiles.call(admin1))
    assert(await config.exerciseC6A.userProfiles.call(admin2))
    assert(await config.exerciseC6A.userProfiles.call(admin3))
    assert(await config.exerciseC6A.userProfiles.call(admin4))
    assert(await config.exerciseC6A.userProfiles.call(admin5))

    // Get initial operational status
    const startStatus = await config.exerciseC6A.operational.call()
    const changeStatus = !startStatus
    assert(startStatus)
    assert(!changeStatus)

    // ACT
    // 1st sig
    await config.exerciseC6A.setOperatingStatus(changeStatus, { from: admin1 })
    assert(await config.exerciseC6A.operational.call())

    // 2nd sig
    await config.exerciseC6A.setOperatingStatus(changeStatus, { from: admin3 })
    assert(await config.exerciseC6A.operational.call())

    // 3rd sig
    await config.exerciseC6A.setOperatingStatus(changeStatus, { from: admin5 })
    assert.equal(await config.exerciseC6A.operational.call(), changeStatus, "Multi-party call failed")

  })
})
